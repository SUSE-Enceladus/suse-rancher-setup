module AWS
  class PrivateSubnet < AWSResource
    attr_accessor :vpc_id, :index, :zone

    def set_route_table!(route_table_id)
      @cli.associate_route_table(self.id, route_table_id)
    end

    private

    def aws_create
      self.creation_attributes = {
        vpc_id: @vpc_id,
        index: @index,
        zone: @zone
      }
      response = @cli.create_subnet(
        @vpc_id, 'private', @index, @zone
      )
      self.id = JSON.parse(response)['Subnet']['SubnetId']
      self.refresh()
    end

    def aws_destroy
      @cli.delete_subnet(self.id)
      throw(:abort) unless Rails.configuration.lasso_run.present?

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
