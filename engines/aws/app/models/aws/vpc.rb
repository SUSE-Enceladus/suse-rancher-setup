require 'json'

module Aws
  class Vpc < Resource
    before_create :aws_create_vpc
    before_destroy :aws_delete_vpc

    def refresh
      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.describe_vpc(self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def aws_create_vpc
      self.engine = 'Aws'

      @cli ||= Aws::Cli.load
      self.framework_raw_response = @cli.create_vpc
      @response = JSON.parse(self.framework_raw_response)
      self.id = @response['Vpc']['VpcId']

      availability_zones = @cli.get_availability_zones
      # if there is an error, return the error
      return availability_zones unless availability_zones.kind_of?(Array)

      # create subnets
      availability_zones.each_with_index do |zone, index|
        Aws::Subnet.create(
          vpc_id: self.id,
          subnet_type: 'public',
          index: index,
          zone: zone
        )
        Aws::Subnet.create(
          vpc_id: self.id,
          subnet_type: 'private',
          index: index,
          zone: zone
        )
      end
      @ig_gw = Aws::InternetGateway.create(vpc_id: self.id)
      raw_describe_subnets_response = @cli.describe_subnets(self.id)
      subnets = JSON.parse(raw_describe_subnets_response)
      subnet_id = ''
      subnets['Subnets'].each do |subnet|
        subnet_id = subnet['SubnetId'] if subnet['CidrBlock'] == '192.168.0.0/19'
      end
      @nat_gw = Aws::NatGateway.create(subnet_id: subnet_id)
    end

    def aws_delete_vpc
      @cli ||= Aws::Cli.load
      @cli.delete_vpc(self.id)
    end
  end
end
