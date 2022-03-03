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

    def execute(args=[])
      stdout, stderr = Cheetah.run(
        ['aws', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => @credential.aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => @credential.aws_secret_access_key,
          'AWS_REGION' => @region
        }
      )
    end

    def version
      args = ['--version']
      stdout, stderr = execute(args)
      return stderr if stderr.present?
      return stdout
    end

    def regions
      args = %w(ec2 describe-regions --output json)
      stdout, stderr = execute(args)
      return stderr if stderr.present?

      regions = JSON.parse(stdout)['Regions'].collect do |region|
        region['RegionName']
      end.sort!
    end
  end
end
