module AWS
  class RouteTable < AWSResource
    attr_accessor :vpc_id, :name

    private

    def set_cli
      @cli = AWS::Cli.load
    end

    def aws_create
      response = @cli.create_route_table(@vpc_id, @name)
      self.id = JSON.parse(response)['RouteTable']['RouteTableId']
      self.refresh()
    end

    def aws_destroy
      self.refresh()
      @framework_attributes['RouteTables'].first['Associations'].each do |association|
        @cli.disassociate_route_table(association['RouteTableAssociationId'])
      end
      @cli.delete_route_table(self.id)
      throw(:abort) unless Rails.application.config.lasso_run.present?

      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_route_table(self.id)
    end

    def state_attribute
      if @framework_attributes['State']
        @framework_attributes['State']
      elsif @framework_attributes['RouteTables']&.first
        'available'
      end
    end
  end
end
