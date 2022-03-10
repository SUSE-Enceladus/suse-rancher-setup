require 'json'

module Aws
  class SecurityGroup < Resource
    before_create :aws_create_security_group
    before_destroy :aws_delete_security_group

    attr_accessor :vpc_id

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_security_group(group_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_security_group
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      tag_value = "curated-installer-sg"
      group_name = "curated-installer-sg"
      self.framework_raw_response = @cli.create_security_group(
        group_name, vpc_id, tag_value
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['GroupId']
    end

    def aws_delete_security_group
      @cli ||= Aws::Cli.load
      @cli.delete_internet_gateway(self.id)
    end
  end
end
