require 'json'

module Aws
  class AllocationAddress < Resource
    after_initialize :set_cli
    before_create :aws_create_allocation_address
    before_destroy :aws_delete_allocation_address

    attr_accessor :subnet_id

    def refresh
      self.framework_raw_response = @cli.describe_allocation_addresses
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def set_cli
      @cli = Aws::Cli.load
    end

    def aws_create_allocation_address
      self.engine = 'Aws'

      self.framework_raw_response = @cli.allocate_address
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['AllocationId']
    end

    def aws_delete_allocation_address
      @cli.release_address(self.id)
    end
  end
end
