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

    def create_subnet(vpc_id, type, zone_index)
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
      cidr_block = public_cidr_blocks[zone_index] if type == 'public'
      cidr_block = private_cidr_blocks[zone_index] if type == 'private'

      availability_zones = _get_availability_zones
      # if there is an error
      return availability_zones unless availability_zones.kind_of?(Array)

      zone = availability_zones[zone_index]
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

    def _get_availability_zones
      args = %W(
        ec2 describe-availability-zones
        --region #{@region} --query AvailabilityZones[*].ZoneName
      )
      stdout, stderr = execute(*args)
      return stderr if stderr.present?

      return JSON.parse(stdout)
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

    def steps
      [:version, :regions, :create_vpc]
    end
  end
end
