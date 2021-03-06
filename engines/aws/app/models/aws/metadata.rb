require 'cheetah'

module AWS
  class Metadata
    include ActiveModel::Model

    attr_accessor(:region)

    def self.load
      new(
        region: Region.load().value,
      )
    end

    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['ec2metadata', '--api', 'latest', *args],
        stdout: :capture,
        stderr: :capture,
        logger: Logger.new(Rails.application.config.cli_log)
      )
      raise StandardError.new(stderr) if stderr.present?

      stdout
    end

    def instance_identity_document
      JSON.parse(self.execute('--document'))
    end

    def account_id
      document = instance_identity_document()
      document['accountId']
    end

    def iam_info
      JSON.parse(self.execute('--info'))
    end

    def instance_profile_arn
      document = iam_info()
      document['InstanceProfileArn']
    end

    def iam_role_name
      arn = instance_profile_arn()
      arn.split('/')[-1]
    end

    def policy_source_arn
      "arn:aws:iam::#{self.account_id()}:role/#{self.iam_role_name()}"
    end
  end
end
