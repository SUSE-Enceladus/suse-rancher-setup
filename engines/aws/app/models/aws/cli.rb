require 'cheetah'
require 'json'

module Aws
  class Cli
    include ActiveModel::Model

    attr_accessor(:credential, :region)

    def initialize(*args)
      super
    end

    def self.load
      new(
        credential: Credential.load(),
        region: Region.load().value
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
          'AWS_DEFAULT_OUTPUT' => 'json'
        }
      )
    end

    def version
      args = ['--version']
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def regions
      args = %w(ec2 describe-regions)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      regions = JSON.parse(stdout)['Regions'].collect do |region|
        region['RegionName']
      end.sort!
    end

    def create_vpc(cidr_block='192.168.0.0/16', vpc_name='curated-installer-vpc')
      tag = "ResourceType=vpc,Tags=[{Key=Name,Value=\"#{vpc_name}\"}]"
      args = %W(
        ec2 create-vpc
        --cidr-block #{cidr_block}
        --tag-specifications #{tag}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_vpc(vpc_id)
      args = %W(ec2 describe-vpcs --vpc-ids #{vpc_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_vpc(vpc_id)
      args = %W(ec2 delete-vpc --vpc-id #{vpc_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_subnets(vpc_id)
      args = %W(ec2 describe-subnets --filters Name=vpc-id,Values=#{vpc_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_subnet(vpc_id, type, index, zone)
      public_cidr_blocks =[
        '192.168.32.0/19',
        '192.168.0.0/19',
        '192.168.64.0/19'
      ]
      private_cidr_blocks = [
        '192.168.128.0/19',
        '192.168.96.0/19',
        '192.168.160.0/19'
      ]
      cidr_block = public_cidr_blocks[index] if type == 'public'
      cidr_block = private_cidr_blocks[index] if type == 'private'

      tag_name = "ResourceType=subnet,Tags=[{Key=Name,Value=curated-installer-vpc/subnet_#{type}_#{zone}}]"
      args = %W(
        ec2 create-subnet
        --cidr-block #{cidr_block}
        --availability-zone #{zone}
        --vpc-id #{vpc_id}
        --tag-specifications #{tag_name}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
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

    def modify_subnet_attribute(subnet_id)
      args = %W(
        ec2 modify-subnet-attribute
        --subnet-id #{subnet_id}
        --map-public-ip-on-launch
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_subnet(subnet_id)
      args = %W(ec2 delete-subnet --subnet-id #{subnet_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_internet_gateways(vpc_id)
      args = %W(
        ec2 describe-internet-gateways
        --filters Name=attachment.vpc-id,Values=#{vpc_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_internet_gateway(ig_name='curated-installed-ig')
      tag = "ResourceType=internet-gateway,Tags=[{Key=Name,Value=\"#{ig_name}\"}]"
      args = %W(
        ec2 create-internet-gateway
        --tag-specifications #{tag}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def attach_internet_gateway(vpc_id, ig_id)
      args = %W(
        ec2 attach-internet-gateway
        --vpc-id #{vpc_id}
        --internet-gateway-id #{ig_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_internet_gateway(ig_id)
      args = %W(ec2 delete-internet-gateway --internet-gateway-id #{ig_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_allocation_addresses
      args = %W(ec2 describe-addresses)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def allocate_address
      args = %W(ec2 allocate-address --domain vpc)
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def release_address(allocation_address_id)
      args = %W(ec2 release-address --allocation-id #{allocation_address_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_nat_gateways(vpc_id)
      args = %W(
        ec2 describe-nat-gateways
        --filter Name=vpc-id,Values=#{vpc_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_nat_gateway(subnet_id, nat_name, allocation_id)
      tag = "ResourceType=natgateway,Tags=[{Key=Name,Value=\"#{nat_name}\"}]"
      args = %W(
        ec2 create-nat-gateway
        --subnet-id #{subnet_id}
        --connectivity-type public
        --tag-specifications #{tag}
        --allocation-id #{allocation_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_nat_gateway(natgw_id)
      args = %W(ec2 delete-nat-gateway --nat-gateway-id #{natgw_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_route_tables(vpc_id)
      filter = "Name=vpc-id,Values=#{vpc_id}"
      args = %W(ec2 describe-route-tables --filters #{filter})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_route_table(vpc_id, tag)
      tag = "ResourceType=route-table, Tags=[{Key=Name,Value=#{tag}}]"
      args = %W(
        ec2 create-route-table
        --vpc-id #{vpc_id}
        --tag-specifications #{tag}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def associate_route_table(subnet_id, route_table_id)
      args = %W(
        ec2 associate-route-table
        --subnet-id #{subnet_id}
        --route-table-id #{route_table_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_route(route_table_id, gw_id)
      args = %W(
        ec2 create-route
        --route-table-id #{route_table_id}
        --gateway-id #{gw_id}
        --destination-cidr-block 0.0.0.0/0
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_route_table(route_table_id)
      args = %W(ec2 delete-route-table --route-table-id #{route_table_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_security_group(vpc_id)
      args = %W(ec2 describe-security-group --vpc-id #{vpc_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_security_group(group_name, vpc_id, tag_value)
      args = %W(
        ec2 create-security-group
        --group-name #{group_name}
        --vpc-id #{vpc_id}
        --description #{tag_value}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_security_group(group_id)
      args = %W(ec2 delete-security_group --group-id #{group_id})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_role(role_name)
      args = %W(iam get-role --role-name #{role_name})
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_role(role_name, role_type)
      document = "cluster-role-trust-policy.json" if role_type == 'cluster'
      document = "node-role-trust-policy.json" if role_type == 'nodegroup'
      assume_policy = "file://#{document}"

      args = %W(
        iam create-role
        --role-name #{role_name}
        --assume-role-policy-document #{assume_policy}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def attach_role_policy(role_name, policy)
      args = %W(
        iam attach-role-policy
        --role-name #{role_name}
        --policy-arn arn:aws:iam::aws:policy/#{policy}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_cluster(cluster_name)
      args = %W(
        eks describe-cluster
        --name #{cluster_name}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_cluster(cluster_name, role_arn, subnets_ids, sg_id)
      args = %W(
        eks create-cluster
        --name #{cluster_name}
        --kubernetes-version 1.21
        --role-arn #{role_arn}
        --resources-vpc-config subnetIds=#{subnets_ids},securityGroupIds=#{sg_id}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_cluster(cluster_name)
      args = %W(
        eks delete-cluster
        --name #{role_name}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def describe_node_group(node_group_name)
      args = %W(
        eks describe-nodegroup
        --nodegroup-name #{node_group_name}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def create_node_group(
      cluster_name, node_group_name, role_arn, public_subnets_ids
    )
      args = %W(
        eks create-nodegroup
        --cluster-name #{cluster_name}
        --nodegroup-name #{node_group_name}
        --scaling-config minSize=2,maxSize=2,desiredSize=2
        --subnets #{public_subnets_ids}
        --instance-types t3.medium
        --ami-type AL2_x86_64
        --node-role #{role_arn}
        --labels role=curated-installer-general-worker
        --capacity-type ON_DEMAND
      )
      # TODO: we need to collect ssh key name for the user to have ssh access
      # --remoteaccess ec2SshKey=ssh_key_name,sourceSecurityGroup=sg_id
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_node_group(node_group_name)
      args = %W(
        eks delete-nodegroup
        --nodergoup-name #{node_group_name}
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def steps
      [:version, :regions, :create_vpc]
    end
  end
end
