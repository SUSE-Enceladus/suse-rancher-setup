module Aws
  class Subnet < AwsResource
    attr_accessor :vpc_id, :subnet_type, :index, :zone

    def map_public_ips!
      @cli.modify_subnet_to_map_public_ips(self.id)
    end

    def set_route_table!(route_table_id)
      @cli.associate_route_table(self.id, route_table_id)
    end

    private

    def aws_create
      response = @cli.create_subnet(
        @vpc_id, @subnet_type, @index, @zone
      )
      self.id = JSON.parse(response)['Subnet']['SubnetId']
      self.refresh()
    end

    def aws_destroy
      @cli.delete_subnet(self.id)
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_subnet(self.id)
    end

    def state_attribute
      @framework_attributes['Subnets'].first['State']
    end
  end
end
