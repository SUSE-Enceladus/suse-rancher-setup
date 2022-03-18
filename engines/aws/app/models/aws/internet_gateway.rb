module Aws
  class InternetGateway < AwsResource

    def attach_to_vpc(vpc_id)
      @cli.attach_internet_gateway(vpc_id, self.id)
      self.refresh()
    end

    private

    def aws_create
      response = @cli.create_internet_gateway
      self.id = JSON.parse(response)['InternetGateway']['InternetGatewayId']
      self.refresh()
    end

    def aws_destroy
      self.refresh()
      @framework_attributes['InternetGateways'].first['Attachments'].each do |attachment|
        @cli.detach_internet_gateway(attachment['VpcId'], self.id)
      end
      @cli.delete_internet_gateway(self.id)
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_internet_gateway(self.id)
    end

    def state_attribute
      if @framework_attributes['State']
        @framework_attributes['State']
      elsif @framework_attributes['InternetGateways']&.first
        'available'
      end
    end
  end
end
