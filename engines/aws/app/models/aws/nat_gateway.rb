require 'json'

module Aws
  class NatGateway < Resource
    after_initialize :set_cli
    before_create :aws_create_nat_gateway
    before_destroy :aws_delete_nat_gateway

    attr_accessor :subnet_id, :allocation_address_id

    def refresh
      self.framework_raw_response = @cli.describe_nat_gateway(self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    def wait_until(desired_status)
      status = ''
      while status != desired_status.to_s
        logger.info "waiting for NAT gateway to be #{desired_status}..."
        begin
          status = JSON.parse(@cli.describe_nat_gateway(self.id))['NatGateways'].first['State']
          sleep(15) if status != 'available'
        rescue
          status = 'nope'
        end
      end
      self
    end

    private

    def set_cli
      @cli = Aws::Cli.load
    end

    def aws_create_nat_gateway
      self.engine = 'Aws'

      self.framework_raw_response = @cli.create_nat_gateway(
        self.subnet_id,
        self.allocation_address_id
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['NatGateway']['NatGatewayId']
    end

    def aws_delete_nat_gateway
      @cli.delete_nat_gateway(self.id)
      self.wait_until(:deleted)
    end
  end
end
