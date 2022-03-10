require 'json'

module Aws
  class Subnet < Resource
    before_create :aws_create_subnet
    before_destroy :aws_delete_subnet

    attr_accessor :vpc_id, :subnet_type, :index, :zone

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_subnets(self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_subnet

      self.engine = 'Aws'

      @cli ||= Aws::Cli.load

      self.framework_raw_response = @cli.create_subnet(
        vpc_id, subnet_type, index, zone
      )
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['Subnet']['SubnetId']
    end

    def aws_delete_subnet
      @cli ||= Aws::Cli.load
      @cli.delete_subnet(self.id)
    end
  end
end
