module AWS
  class Vpc < AWSResource

    def modify_vpc_attrs
      ['--enable-dns-hostnames', '--enable-dns-support'].each do |attr|
        @cli.modify_vpc_attribute(self.id, attr)
      end
      self.refresh()
    end
    private

    def aws_create
      response = @cli.create_vpc()
      self.id = JSON.parse(response)['Vpc']['VpcId']
      self.refresh()
      # self.wait_until(:available)
    end

    def aws_destroy
      @cli.delete_vpc(self.id)
      throw(:abort) unless Rails.application.config.lasso_run.present?

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
