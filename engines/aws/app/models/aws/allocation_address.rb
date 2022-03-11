require 'json'

module Aws
  class AllocationAddress < Resource
    before_create :aws_create_allocation_address
    before_destroy :aws_delete_allocation_address

    attr_accessor :subnet_id

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_allocation_addresses
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_allocation_address
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      self.framework_raw_response = @cli.allocate_address
      puts self.framework_raw_response
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['AllocationId']
    end

    def aws_delete_allocation_address
      @cli ||= Aws::Cli.load
      @cli.delete_subnet(self.id)
    end
  end
end
