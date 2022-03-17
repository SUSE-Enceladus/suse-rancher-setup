require 'json'

module Aws
  class NatGateway < Resource
    before_create :aws_create_nat_gateway
    before_destroy :aws_delete_nat_gateway

    attr_accessor :subnet_id

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_nat_gateways(vpc_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_nat_gateway
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      allocation_address = Aws::AllocationAddress.create
      self.framework_raw_response = @cli.create_nat_gateway(
        subnet_id,
        allocation_address.id
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['NatGateway']['NatGatewayId']
    end

    def aws_delete_nat_gateway
      @cli ||= Aws::Cli.load
      @cli.delete_nat_gateway(self.id)
    end
  end
end
