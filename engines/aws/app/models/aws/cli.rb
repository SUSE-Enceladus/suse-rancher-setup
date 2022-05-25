require 'cheetah'

module AWS
  class Cli
    include ActiveModel::Model

    attr_accessor(:credential, :region, :tag_scope)

    def self.load
      new(
        credential: Credential.load(),
        region: Region.load().value,
        tag_scope: KeyValue.get('tag_scope', 'curated-cloud-installer')
      )
    end

    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['aws', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => @credential.aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => @credential.aws_secret_access_key,
          'AWS_REGION' => @region,
          'AWS_DEFAULT_REGION' => @region,
          'AWS_DEFAULT_OUTPUT' => 'json'
        }
      )
    end

    def get_description(args, not_found_exception, not_found_response)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    rescue Cheetah::ExecutionFailed => err
      if err.stderr.include?(not_found_exception)
        not_found_response
      end
    end

    def handle_command(args)
      if Rails.application.config.lasso_run.present?
        stdout, stderr = execute(*args)
        return stderr if stderr.present?
        return stdout
      else
        File.open(Rails.application.config.lasso_commands_file, 'a') do |f|
          envs = "AWS_ACCESS_KEY_ID=#{@credential.aws_access_key_id} AWS_SECRET_ACCESS_KEY=#{@credential.aws_secret_access_key}"
          f.write "#{envs} aws #{args.join(' ')} --region #{@region} --output json\n"
        end
      end
    end

    def version
      args = ['--version']
      handle_command(args)
    end

    def regions
      args = %w(ec2 describe-regions)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      regions = JSON.parse(stdout)['Regions'].collect do |region|
        region['RegionName']
      end.sort!
    end

    def describe_instance_type_offerings(region, instance_types)
      args = %W(
        ec2 describe-instance-type-offerings
        --location-type availability-zone
        --filters Name=instance-type,Values=#{instance_types}
        --query InstanceTypeOfferings[].InstanceType
        --region #{region}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      JSON.parse(stdout)
    end

    def validate_credentials(aws_access_key_id, aws_secret_access_key)
      args = %w(ec2 describe-regions)
      stdout, stderr = Cheetah.run(
        ['aws', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => aws_secret_access_key,
          'AWS_REGION' => @region,
          'AWS_DEFAULT_REGION' => @region,
          'AWS_DEFAULT_OUTPUT' => 'json'
        }
      )
      return stderr if stderr.present?

      JSON.parse(stdout)['Regions']
    end

    def create_vpc(cidr_block='192.168.0.0/16', name='vpc')
      tag = "ResourceType=vpc,Tags=[{Key=Name,Value=\"#{self.tag_scope}/#{name}\"}]"
      args = %W(
        ec2 create-vpc
        --cidr-block #{cidr_block}
        --tag-specifications #{tag}
      )
      handle_command(args)
    end

    def describe_vpc(vpc_id)
      args = %W(ec2 describe-vpcs --vpc-ids #{vpc_id})
      get_description(
        args, 'InvalidVpcID.NotFound', '{"Vpcs": [{"State": "not_found"}]}'
      )
    end

    def delete_vpc(vpc_id)
      args = %W(ec2 delete-vpc --vpc-id #{vpc_id})
      handle_command(args)
    end

    def describe_subnet(subnet_id)
      args = %W(ec2 describe-subnets --subnet-ids #{subnet_id})
      get_description(args, '.NotFound', '{"Subnets": [{"State": "not_found"}]}')
    end

    def list_availability_zones_supporting_instance_type(instance_type)
      args = %W(
        ec2 describe-instance-type-offerings
        --location-type availability-zone
        --filters Name=instance-type,Values=#{instance_type}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      zones = JSON.parse(stdout)['InstanceTypeOfferings'].collect do |offering|
        offering['Location']
      end.sort!
    end

    def create_subnet(vpc_id, type, index, zone)
      cidr_blocks = {
        'public' => [
          '192.168.0.0/19',
          '192.168.32.0/19',
          '192.168.64.0/19'
        ],
        'private' => [
          '192.168.96.0/19',
          '192.168.128.0/19',
          '192.168.160.0/19'
        ]
      }
      cidr_block = cidr_blocks[type][index]
      tag_name = "ResourceType=subnet,Tags=[{Key=Name,Value=#{self.tag_scope}/subnet_#{type}_#{zone}}]"
      args = %W(
        ec2 create-subnet
        --cidr-block #{cidr_block}
        --availability-zone #{zone}
        --vpc-id #{vpc_id}
        --tag-specifications #{tag_name}
      )
      handle_command(args)
    end

    def get_availability_zones
      args = %W(
        ec2 describe-availability-zones
        --region #{@region} --query AvailabilityZones[*].ZoneName
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      return JSON.parse(stdout)
    end

    def modify_subnet_to_map_public_ips(subnet_id)
      args = %W(
        ec2 modify-subnet-attribute
        --subnet-id #{subnet_id}
        --map-public-ip-on-launch
      )
      handle_command(args)
    end

    def delete_subnet(subnet_id)
      args = %W(ec2 delete-subnet --subnet-id #{subnet_id})
      handle_command(args)
    end

    def describe_internet_gateway(igw_id)
      args = %W(
        ec2 describe-internet-gateways
        --internet-gateway-ids #{igw_id}
      )
      get_description(args, '.NotFound', '{"State": "not_found"}')
    end

    def create_internet_gateway(name='internet-gateway')
      tag = "ResourceType=internet-gateway,Tags=[{Key=Name,Value=#{self.tag_scope}/#{name}}]"
      args = %W(
        ec2 create-internet-gateway
        --tag-specifications #{tag}
      )
      handle_command(args)
    end

    def attach_internet_gateway(vpc_id, ig_id)
      args = %W(
        ec2 attach-internet-gateway
        --vpc-id #{vpc_id}
        --internet-gateway-id #{ig_id}
      )
      handle_command(args)
    end

    def detach_internet_gateway(vpc_id, igw_id)
      args = %W(
        ec2 detach-internet-gateway
        --internet-gateway-id #{igw_id}
        --vpc-id #{vpc_id}
      )
      handle_command(args)
    end

    def delete_internet_gateway(ig_id)
      args = %W(ec2 delete-internet-gateway --internet-gateway-id #{ig_id})
      handle_command(args)
    end

    def describe_allocation_address(eip_id)
      args = %W(ec2 describe-addresses --allocation-ids #{eip_id})
      get_description(args, 'InvalidAllocationID.NotFound', '{"State": "not_found"}')
    end

    def allocate_address(name='elastic-ip')
      tag = "ResourceType=elastic-ip,Tags=[{Key=Name,Value=#{self.tag_scope}/#{name}}]"
      args = %W(ec2 allocate-address --domain vpc --tag-specifications #{tag})
      handle_command(args)
    end

    def release_address(allocation_address_id)
      args = %W(ec2 release-address --allocation-id #{allocation_address_id})
      handle_command(args)
    end

    def describe_nat_gateway(nat_id)
      args = %W(ec2 describe-nat-gateways --nat-gateway-ids #{nat_id})
      handle_command(args)
    end

    def create_nat_gateway(subnet_id, allocation_id, name='nat-gateway')
      tag = "ResourceType=natgateway,Tags=[{Key=Name,Value=#{self.tag_scope}/#{name}}]"
      args = %W(
        ec2 create-nat-gateway
        --subnet-id #{subnet_id}
        --connectivity-type public
        --tag-specifications #{tag}
        --allocation-id #{allocation_id}
      )
      handle_command(args)
    end

    def delete_nat_gateway(natgw_id)
      args = %W(ec2 delete-nat-gateway --nat-gateway-id #{natgw_id})
      handle_command(args)
    end

    def describe_route_table(route_table_id)
      args = %W(ec2 describe-route-tables --route-table-ids #{route_table_id})
      get_description(args, '.NotFound', '{"State": "not_found"}')
    end

    def create_route_table(vpc_id, name='public-route-table')
      tag = "ResourceType=route-table,Tags=[{Key=Name,Value=#{self.tag_scope}/#{name}}]"
      args = %W(
        ec2 create-route-table
        --vpc-id #{vpc_id}
        --tag-specifications #{tag}
      )
      handle_command(args)
    end

    def associate_route_table(subnet_id, route_table_id)
      args = %W(
        ec2 associate-route-table
        --subnet-id #{subnet_id}
        --route-table-id #{route_table_id}
      )
      handle_command(args)
    end

    def disassociate_route_table(association_id)
      args = %W(
        ec2 disassociate-route-table
        --association-id #{association_id}
      )
      handle_command(args)
    end

    def create_route(route_table_id, gw_id)
      args = %W(
        ec2 create-route
        --route-table-id #{route_table_id}
        --gateway-id #{gw_id}
        --destination-cidr-block 0.0.0.0/0
      )
      handle_command(args)
    end

    def delete_route_table(route_table_id)
      args = %W(ec2 delete-route-table --route-table-id #{route_table_id})
      handle_command(args)
    end

    def describe_security_group(group_id)
      args = %W(ec2 describe-security-groups --group-ids #{group_id})
      get_description(args, '.NotFound', '{"State": "not_found"}')
    end

    def create_security_group(vpc_id)
      description = "Security group for #{tag_scope}"
      args = %W(
        ec2 create-security-group
        --vpc-id #{vpc_id}
        --group-name #{@tag_scope}-sg
        --description #{description}
      )
      # --description \"Security Group for #{@tag_scope}\"
      handle_command(args)
    rescue StandardError => e
      debugger
    end

    def delete_security_group(group_id)
      args = %W(ec2 delete-security-group --group-id #{group_id})
      handle_command(args)
    end

    def describe_role(role_name)
      args = %W(iam get-role --role-name #{role_name})
      get_description(args, 'NoSuchEntity', '{"State": "not_found"}')
    end

    def list_role_attached_policies(name)
      args = %W(
        iam list-attached-role-policies
        --role-name #{name}
      )
      handle_command(args)
    end

    def create_role(name, target)
      role_name = "#{@tag_scope}-#{name}"
      policy_doc = "file://#{File.dirname(__FILE__)}/#{target}-role-trust-policy.json"
      args = %W(
        iam create-role
        --role-name #{role_name}
        --assume-role-policy-document #{policy_doc}
      )
      handle_command(args)
    end

    def delete_role(name)
      args = %W(
        iam delete-role
        --role-name #{name}
      )
      handle_command(args)
    end

    def attach_role_policy(name, policy)
      args = %W(
        iam attach-role-policy
        --role-name #{name}
        --policy-arn arn:aws:iam::aws:policy/#{policy}
      )
      handle_command(args)
    end

    def detach_role_policy(role_name, policy_arn)
      args = %W(
        iam detach-role-policy
        --role-name #{role_name}
        --policy-arn #{policy_arn}
      )
      handle_command(args)
    end

    def describe_cluster(cluster_name)
      args = %W(
        eks describe-cluster
        --name #{cluster_name}
      )
      get_description(args, 'ResourceNotFoundException', '{"cluster": {"status": "not_found"}}')
    end

    def create_cluster(role_arn, subnets_ids, sg_id, k8s_version='1.20')
      name = "#{@tag_scope}-cluster"
      args = %W(
        eks create-cluster
        --name #{name}
        --kubernetes-version #{k8s_version}
        --role-arn #{role_arn}
        --resources-vpc-config subnetIds=#{subnets_ids},securityGroupIds=#{sg_id}
      )
      handle_command(args)
    end

    def delete_cluster(name)
      args = %W(
        eks delete-cluster
        --name #{name}
      )
      handle_command(args)
    end

    def update_kube_config(cluster_name, kubeconfig="/tmp/kubeconfig")
      FileUtils.rm_f(kubeconfig)
      args = %W(
        eks update-kubeconfig
        --name #{cluster_name}
        --kubeconfig #{kubeconfig}
      )
      handle_command(args)
    end

    def describe_node_group(node_group_name, cluster_name)
      args = %W(
        eks describe-nodegroup
        --nodegroup-name #{node_group_name}
        --cluster-name #{cluster_name}
      )
      get_description(args, 'ResourceNotFoundException', '{"nodegroup": {"status": "not_found"}}')
    end

    def create_node_group(cluster_name, role_arn, public_subnet_ids,
        instance_type, instance_count
      )
      name = "#{cluster_name}-nodegroup"
      role = "#{cluster_name}-general-worker"
      scaling_config = [
        "minSize=#{instance_count - 1}",
        "maxSize=#{instance_count + 1}",
        "desiredSize=#{instance_count}"
      ]
      args = %W(
        eks create-nodegroup
        --cluster-name #{cluster_name}
        --nodegroup-name #{name}
        --scaling-config #{scaling_config.join(',')}
        --instance-types #{instance_type}
        --ami-type AL2_x86_64
        --node-role #{role_arn}
        --labels role=#{role}
        --capacity-type ON_DEMAND
        --subnets
      )
      args << public_subnet_ids
      handle_command(args)
    rescue Cheetah::ExecutionFailed => err
      puts err.stderr
      debugger
    end

    def delete_node_group(node_group_name, cluster_name)
      args = %W(
        eks delete-nodegroup
        --nodegroup-name #{node_group_name}
        --cluster-name #{cluster_name}
      )
      handle_command(args)
    end

    def get_hosted_zones(dns_name)
      args = %W(route53 list-hosted-zones-by-name --dns-name #{dns_name})
      handle_command(args)
    end

    def get_hosted_zone_id(domain)
      args = %W(route53 list-hosted-zones-by-name --dns-name #{domain})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      JSON.parse(stdout)['HostedZones'].first['Id']
    end

    def list_dns_records(domain)
      zone_id = self.get_hosted_zone_id(domain)
      args = %W(route53 list-resource-record-sets --hosted-zone-id #{zone_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      JSON.parse(stdout)['ResourceRecordSets']
    end

    def create_dns_record(hosted_zone_id, fqdn, target, record_type)
      tmp_path = '/tmp/dns_record.json'
      change_batch = {
        "Comment": "Update record for Ingress controller",
        "Changes": [
          {
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "#{fqdn}",
              "Type": "#{record_type}",
              "TTL": 900,
              "ResourceRecords": [
                {
                  "Value": "#{target}"
                }
              ]
            }
          }
        ]
      }
      File.open(tmp_path, 'w') do |f|
        f.write(change_batch.to_json)
      end

      args = %W(
        route53 change-resource-record-sets
        --hosted-zone-id #{hosted_zone_id}
        --change-batch file://#{tmp_path}
      )
      output = handle_command(args)
      FileUtils.rm_f(tmp_path)
      output
    end

    def route53_get_change(id)
      args = %W(route53  get-change --id #{id})
      handle_command(args)
    end

    def steps
      [:version, :regions, :create_vpc]
    end
  end
end
