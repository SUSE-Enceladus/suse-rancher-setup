require 'json'

module Aws
  class RouteTable < Resource
    before_create :aws_create_route_table
    before_destroy :aws_delete_route_table

    attr_accessor :vpc_id, :tag

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_route_tables(vpc_id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_route_table
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      self.framework_raw_response = @cli.create_route_table(vpc_id, tag)
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['RouteTable']['RouteTableId']
    end

    def aws_delete_route_table
      @cli ||= Aws::Cli.load
      @cli.delete_route_table(self.id)
    end
  end
end
