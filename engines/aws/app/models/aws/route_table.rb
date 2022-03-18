require 'json'

module Aws
  class RouteTable < Resource
    after_initialize :set_cli
    before_create :aws_create_route_table
    before_destroy :aws_delete_route_table

    attr_accessor :vpc_id, :name

    def refresh
      self.framework_raw_response = @cli.describe_route_table(self.id)
      @response = JSON.parse(self.framework_raw_response)['RouteTables'].first
    end

    private

    def set_cli
      @cli = Aws::Cli.load
    end

    def aws_create_route_table
      self.engine = 'Aws'

      self.framework_raw_response = @cli.create_route_table(self.vpc_id, self.name)
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['RouteTable']['RouteTableId']
    end

    def aws_delete_route_table
      self.refresh()
      @response['Associations'].each do |association|
        @cli.disassociate_route_table(association['RouteTableAssociationId'])
      end
      @cli.delete_route_table(self.id)
    end
  end
end
