require 'json'

module Aws
  class Subnet < Resource
    after_initialize :set_cli
    before_create :aws_create_subnet
    before_destroy :aws_delete_subnet

    attr_accessor :vpc_id, :subnet_type, :index, :zone

    def refresh
      self.framework_raw_response = @cli.describe_subnets(self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    def map_public_ips!
      @cli.modify_subnet_to_map_public_ips(self.id)
    end

    def set_route_table!(route_table_id)
      @cli.associate_route_table(self.id, route_table_id)
    end

    private

    def set_cli
      @cli = Aws::Cli.load
    end

    def aws_create_subnet
      self.engine = 'Aws'

      self.framework_raw_response = @cli.create_subnet(
        vpc_id, subnet_type, index, zone
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['Subnet']['SubnetId']
    end

    def aws_delete_subnet
      @cli.delete_subnet(self.id)
    end
  end
end
