module AWS
  class Cli < Executable
    def environment()
      {
        'AWS_REGION' => @region,
        'AWS_DEFAULT_REGION' => @region,
        'AWS_DEFAULT_OUTPUT' => 'json'
      }
    end

    def command()
      'aws'
    end

    def get_description(args, not_found_exception, not_found_response)
      execute(*args)
    rescue Executable::CliError => err
      if err.message.include?(not_found_exception)
        not_found_response
      else
        raise CliError.new(err.stderr)
      end
    end

    def version
      args = ['--version']
      execute(args)
    end

    def regions
      args = %w(ec2 describe-regions)
      stdout = execute(*args)
      regions = JSON.parse(stdout)['Regions'].collect do |region|
        region['RegionName']
      end.sort!
    rescue StandardError => err
      Rails.logger.error err.message
      return err.message
    end

    def describe_instance_type_offerings(region, instance_types)
      args = %W(
        ec2 describe-instance-type-offerings
        --region #{region}
        --location-type availability-zone
        --filters Name=instance-type,Values=#{instance_types}
        --query InstanceTypeOfferings[].InstanceType
      )
      stdout = execute(*args)
      JSON.parse(stdout)
    end

    def create_vpc(cidr_block='192.168.0.0/16', name='vpc')
      tag = "ResourceType=vpc,Tags=[{Key=Name,Value=\"#{self.tag_scope}/#{name}\"}]"
      args = %W(
        ec2 create-vpc
        --cidr-block #{cidr_block}
        --tag-specifications #{tag}
      )
      execute(args)
    end

    def modify_vpc_attribute(vpc_id, attribute)
      args = %W(
        ec2 modify-vpc-attribute
        --vpc-id #{vpc_id}
        #{attribute}
      )
      execute(args)
    end

    def list_vpc_ids()
      args = %W(ec2 describe-vpcs --no-paginate --query Vpcs[].VpcId)
      execute(args)
    end

    def describe_vpc(vpc_id)
      args = %W(ec2 describe-vpcs --vpc-ids #{vpc_id})
      get_description(
        args, 'InvalidVpcID.NotFound', '{"Vpcs": [{"State": "not_found"}]}'
      )
    end

    def delete_vpc(vpc_id)
      args = %W(ec2 delete-vpc --vpc-id #{vpc_id})
      execute(args)
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
      stdout = execute(*args)
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
      execute(args)
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
      execute(args)
    end

    def delete_subnet(subnet_id)
      args = %W(ec2 delete-subnet --subnet-id #{subnet_id})
      execute(args)
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
      execute(args)
    end

    def attach_internet_gateway(vpc_id, ig_id)
      args = %W(
        ec2 attach-internet-gateway
        --vpc-id #{vpc_id}
        --internet-gateway-id #{ig_id}
      )
      execute(args)
    end

    def detach_internet_gateway(vpc_id, igw_id)
      args = %W(
        ec2 detach-internet-gateway
        --internet-gateway-id #{igw_id}
        --vpc-id #{vpc_id}
      )
      execute(args)
    end

    def delete_internet_gateway(ig_id)
      args = %W(ec2 delete-internet-gateway --internet-gateway-id #{ig_id})
      execute(args)
    end

    def describe_allocation_address(eip_id)
      args = %W(ec2 describe-addresses --allocation-ids #{eip_id})
      get_description(args, 'InvalidAllocationID.NotFound', '{"State": "not_found"}')
    end

    def allocate_address(name='elastic-ip')
      tag = "ResourceType=elastic-ip,Tags=[{Key=Name,Value=#{self.tag_scope}/#{name}}]"
      args = %W(ec2 allocate-address --domain vpc --tag-specifications #{tag})
      execute(args)
    end

    def release_address(allocation_address_id)
      args = %W(ec2 release-address --allocation-id #{allocation_address_id})
      execute(args)
    end

    def describe_nat_gateway(nat_id)
      args = %W(ec2 describe-nat-gateways --nat-gateway-ids #{nat_id})
      execute(args)
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
      execute(args)
    end

    def delete_nat_gateway(natgw_id)
      args = %W(ec2 delete-nat-gateway --nat-gateway-id #{natgw_id})
      execute(args)
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
      execute(args)
    end

    def associate_route_table(subnet_id, route_table_id)
      args = %W(
        ec2 associate-route-table
        --subnet-id #{subnet_id}
        --route-table-id #{route_table_id}
      )
      execute(args)
    end

    def disassociate_route_table(association_id)
      args = %W(
        ec2 disassociate-route-table
        --association-id #{association_id}
      )
      execute(args)
    end

    def create_route(route_table_id, gw_id)
      args = %W(
        ec2 create-route
        --route-table-id #{route_table_id}
        --gateway-id #{gw_id}
        --destination-cidr-block 0.0.0.0/0
      )
      execute(args)
    end

    def delete_route_table(route_table_id)
      args = %W(ec2 delete-route-table --route-table-id #{route_table_id})
      execute(args)
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
      execute(args)
    end

    def delete_security_group(group_id)
      args = %W(ec2 delete-security-group --group-id #{group_id})
      execute(args)
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
      execute(args)
    end

    def create_role(name, target)
      role_name = "#{@tag_scope}-#{name}"
      FileUtils.cp("#{File.dirname(__FILE__)}/#{target}-role-trust-policy.json", "/tmp/#{target}-role-trust-policy.json")
      policy_doc = "file:///tmp/#{target}-role-trust-policy.json"
      args = %W(
        iam create-role
        --role-name #{role_name}
        --assume-role-policy-document #{policy_doc}
      )
      execute(args)
    end

    def delete_role(name)
      args = %W(
        iam delete-role
        --role-name #{name}
      )
      execute(args)
    end

    def attach_role_policy(name, policy)
      args = %W(
        iam attach-role-policy
        --role-name #{name}
        --policy-arn arn:aws:iam::aws:policy/#{policy}
      )
      execute(args)
    end

    def detach_role_policy(role_name, policy)
      args = %W(
        iam detach-role-policy
        --role-name #{role_name}
        --policy-arn arn:aws:iam::aws:policy/#{policy}
      )
      execute(args)
    end

    def describe_cluster(cluster_name)
      args = %W(
        eks describe-cluster
        --name #{cluster_name}
      )
      get_description(args, 'ResourceNotFoundException', '{"cluster": {"status": "not_found"}}')
    end

    def create_cluster(role_arn, subnets_ids, sg_id, k8s_version)
      name = "#{@tag_scope}-cluster"
      args = %W(
        eks create-cluster
        --name #{name}
        --kubernetes-version #{k8s_version}
        --role-arn #{role_arn}
        --resources-vpc-config subnetIds=#{subnets_ids},securityGroupIds=#{sg_id}
      )
      execute(args)
    end

    def delete_cluster(name)
      args = %W(
        eks delete-cluster
        --name #{name}
      )
      execute(args)
    end

    def update_kube_config(cluster_name, kubeconfig=Rails.configuration.kubeconfig)
      FileUtils.rm_f(kubeconfig) unless Rails.configuration.record_commands
      args = %W(
        eks update-kubeconfig
        --name #{cluster_name}
        --kubeconfig #{kubeconfig}
      )
      execute(args)
      FileUtils.chmod(0600, kubeconfig)
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
      execute(args)
    end

    def delete_node_group(node_group_name, cluster_name)
      args = %W(
        eks delete-nodegroup
        --nodegroup-name #{node_group_name}
        --cluster-name #{cluster_name}
      )
      execute(args)
    end

    def get_hosted_zones(dns_name)
      args = %W(route53 list-hosted-zones-by-name --dns-name #{dns_name})
      execute(args)
    end

    def get_hosted_zone_id(domain)
      args = %W(route53 list-hosted-zones-by-name --dns-name #{domain})
      stdout = execute(*args)
      hosted_zones = JSON.parse(stdout)['HostedZones']
      hosted_zone = hosted_zones.select {|hosted_zone| hosted_zone['Name'] == (domain + ".")}
      return hosted_zone[0]['Id'] if hosted_zone.length > 0

      return nil
    end

    def list_dns_records(domain)
      zone_id = self.get_hosted_zone_id(domain)
      args = %W(route53 list-resource-record-sets --hosted-zone-id #{zone_id})
      stdout = execute(*args)
      JSON.parse(stdout)['ResourceRecordSets']
    rescue Cheetah::ExecutionFailed
      return []
    end

    def create_dns_record(hosted_zone_id, fqdn, target, record_type)
      change_batch = get_change_batch(
        "Update record for Ingress controller", "UPSERT", fqdn, record_type, target
      )
      write_change_batch(change_batch)
      args = %W(
        route53 change-resource-record-sets
        --hosted-zone-id #{hosted_zone_id}
        --change-batch file://#{Rails.configuration.lasso_dns_json_path}
      )
      output = execute(args)
      FileUtils.rm_f(Rails.configuration.lasso_dns_json_path)
      output
    end

    def get_change_batch(comment, operation, fqdn, record_type, target)
      change_batch = {
        "Comment": "#{comment}",
        "Changes": [
          {
            "Action": "#{operation}",
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
      change_batch
    end

    def write_change_batch(change_batch)
      File.open(Rails.configuration.lasso_dns_json_path, 'w') do |f|
        f.write(change_batch.to_json)
      end
    end

    def delete_dns_record(hosted_zone_id, fqdn, target, record_type)
      change_batch = get_change_batch(
        "Delete suse-rancher-setup record set", "DELETE", fqdn, record_type, target
      )
      args = %W(
        route53 change-resource-record-sets
        --hosted-zone-id #{hosted_zone_id}
        --change-batch #{JSON.generate(change_batch)}
      )
      execute(args)
    end

    def route53_get_change(id)
      args = %W(route53  get-change --id #{id})
      execute(args)
    end

    def simulate_principal_policy(arn, *actions)
      args = %W(iam simulate-principal-policy --policy-source-arn #{arn} --action-names)
      args.push(*actions)
      execute(args)
    end

    def get_quota(service:, code:)
      args = %W(service-quotas get-service-quota --service-code #{service} --quota-code #{code})
      execute(args)
    end

    def steps
      [:version, :regions, :create_vpc]
    end
  end
end
