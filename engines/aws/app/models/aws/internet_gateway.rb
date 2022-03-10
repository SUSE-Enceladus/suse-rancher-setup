require 'json'

module Aws
  class InternetGateway < Resource
    before_create :aws_create_internet_gateway
    before_destroy :aws_delete_internet_gateway

    attr_accessor :vpc_id

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_internet_gateways(vpc_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_internet_gateway
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      self.framework_raw_response = @cli.create_internet_gateway
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['InternetGateway']['InternetGatewayId']
      @cli.attach_internet_gateway(vpc_id, self.id)
    end

    def aws_delete_internet_gateway
      @cli ||= Aws::Cli.load
      @cli.delete_internet_gateway(self.id)
    end
  end
end
