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

    def create_vpc(cidr_block='10.0.0.0/16')
      args = %w(ec2 create-vpc --cidr-block)
      args << cidr_block
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def delete_vpc(vpc_id)
      args = %w(ec2 delete-vpc --vpc-id)
      args << vpc_id
      stdout, stderr = execute(*args)
      return stderr if stderr.present?
      return stdout
    end

    def steps
      [:version, :regions, :create_vpc]
    end
  end
end
