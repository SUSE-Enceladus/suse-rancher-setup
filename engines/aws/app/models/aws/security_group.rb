module AWS
  class SecurityGroup < AWSResource
    attr_accessor :vpc_id

    def create_command
      response = @cli.create_security_group(vpc_id)
      self.id = JSON.parse(response)['GroupId']
    end

    def destroy_command
      @cli.delete_security_group(self.id)
      throw(:abort) unless Rails.configuration.lasso_run.present?
    end

    def describe_resource
      @cli.describe_security_group(self.id)
    end

    def state_attribute
      if @framework_attributes['State']
        @framework_attributes['State']
      elsif @framework_attributes['SecurityGroups']&.first
        'available'
      end
    end
  end
end
