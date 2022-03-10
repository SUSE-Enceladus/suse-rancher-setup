require 'json'

module Aws
  class Vpc < Resource
    before_create :aws_create_vpc
    before_destroy :aws_delete_vpc

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_vpc(self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_vpc
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.create_vpc
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['Vpc']['VpcId']
    end

    def aws_delete_vpc
      @cli ||= Aws::Cli.load
      @cli.delete_vpc(self.id)
    end
  end
end
