module Aws
  class AllocationAddress < AwsResource

    private

    def aws_create
      response = @cli.allocate_address
      self.id = JSON.parse(response)['AllocationId']
      self.refresh()
    end

    def aws_destroy(f=nil)
      @cli.release_address(self.id, f)
      self.wait_until(:not_found)
    end

    def describe_resource
      begin
        @cli.describe_allocation_address(self.id)
      rescue Cheetah::ExecutionFailed
        return ''
      end
    end

    def state_attribute
      if @framework_attributes['State']
        @framework_attributes['State']
      elsif @framework_attributes['Addresses']&.first
        'available'
      end
    end
  end
end
