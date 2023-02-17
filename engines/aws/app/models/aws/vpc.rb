module AWS
  class Vpc < AWSResource

    def modify_vpc_attrs
      ['--enable-dns-hostnames', '--enable-dns-support'].each do |attr|
        @cli.modify_vpc_attribute(self.id, attr)
      end
      self.refresh()
    end

    def create_command
      response = @cli.create_vpc()
      self.id = JSON.parse(response)['Vpc']['VpcId']
      self.refresh()
      # self.wait_until(:available)
    end

    def destroy_command
      @cli.delete_vpc(self.id)
    end

    def wait_for_destroy_command
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_vpc(self.id)
    end

    def state_attribute
      @framework_attributes['Vpcs'].first['State']
    end
  end
end
