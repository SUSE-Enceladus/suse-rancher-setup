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

      public_route_table = Aws::RouteTable.create(
        vpc_id: self.id,
        tag: "curated-installer/public-route-table"
      )
      private_route_table_ids = []
      # create subnets and private route tables
      availability_zones.each_with_index do |zone, index|
        public_subnet = Aws::Subnet.create(
          vpc_id: self.id,
          subnet_type: 'public',
          index: index,
          zone: zone
        )
        private_subnet = Aws::Subnet.create(
          vpc_id: self.id,
          subnet_type: 'private',
          index: index,
          zone: zone
        )
        private_route_table = Aws::RouteTable.create(
          vpc_id: self.id,
          tag: "curated-installer/private-route-table-#{zone}"
        )
        @cli.modify_subnet_attribute(public_subnet.id)
        @cli.associate_route_table(private_subnet.id, private_route_table.id)
        @cli.associate_route_table(public_subnet.id, public_route_table.id)
        private_route_table_ids << private_route_table.id
      end
      @igw = Aws::InternetGateway.create(vpc_id: self.id)
      raw_describe_subnets_response = @cli.describe_subnets(self.id)
      subnets = JSON.parse(raw_describe_subnets_response)
      subnet_id = ''
      subnets['Subnets'].each do |subnet|
        subnet_id = subnet['SubnetId'] if subnet['CidrBlock'] == '192.168.0.0/19'
      end
      @nat_gw = Aws::NatGateway.create(subnet_id: subnet_id)
      status = ''
      while status != 'available'
        sleep(60) # NAT gateway is not active yet, wait 60 seconds
        puts "waiting (60 seconds) for NAT gateway to be available"
        describe_nat_response = @cli.describe_nat_gateways(self.id)
        describe_nat_response = JSON.parse(describe_nat_response)
        describe_nat_response['NatGateways'].each do |nat|
          status = nat['State']
        end
      end
      private_route_table_ids.each do |private_route_table_id|
        @cli.create_route(private_route_table_id, @nat_gw.id)
      end
      @cli.create_route(public_route_table.id, @igw.id)
    end

    def aws_delete_vpc
      @cli ||= Aws::Cli.load
      @cli.delete_vpc(self.id)
    end
  end
end
