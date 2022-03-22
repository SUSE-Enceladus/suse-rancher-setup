module Aws
  class NatGateway < AwsResource
    attr_accessor :subnet_id, :allocation_address_id, :internet_gateway_id

    private

    def aws_create
      response = JSON.parse(
        @cli.describe_internet_gateway(@internet_gateway_id)
      )
      begin
        response['InternetGateways'].first['Attachments'].first
      rescue
        raise 'Internet Gateway must be present and attached to VPC'
      end
      response = @cli.create_nat_gateway(
        @subnet_id,
        @allocation_address_id
      )
      self.id = JSON.parse(response)['NatGateway']['NatGatewayId']
      self.refresh()
      # self.wait_until(:available)
    end

    def aws_destroy
      @cli.delete_nat_gateway(self.id)
      self.wait_until(:deleted)
    end

    def describe_resource
      @cli.describe_nat_gateway(self.id)
    end

    def state_attribute
      @framework_attributes['NatGateways'].first['State']
    end
  end
end
