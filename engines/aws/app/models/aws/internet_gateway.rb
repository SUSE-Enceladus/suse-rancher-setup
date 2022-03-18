require 'json'

module Aws
  class InternetGateway < Resource
    after_initialize :set_cli
    before_create :aws_create_internet_gateway
    before_destroy :aws_delete_internet_gateway

    attr_accessor :vpc_id

    def refresh
      self.framework_raw_response = @cli.describe_internet_gateway(self.id)
      @response = JSON.parse(self.framework_raw_response)['InternetGateways'].first
    end

    private

    def set_cli
      @cli = Aws::Cli.load
    end

    def aws_create_internet_gateway
      self.engine = 'Aws'

      self.framework_raw_response = @cli.create_internet_gateway
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['InternetGateway']['InternetGatewayId']
      @cli.attach_internet_gateway(vpc_id, self.id)
    end

    def aws_delete_internet_gateway
      self.refresh()
      @response['Attachments'].each do |attachment|
        @cli.detach_internet_gateway(attachment['VpcId'], self.id)
      end
      @cli.delete_internet_gateway(self.id)
    end
  end
end
