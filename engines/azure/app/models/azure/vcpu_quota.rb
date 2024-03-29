module Azure
  class VcpuQuota < Azure::Quota
    attr_accessor :instance_type, :quantity

    def instance_family
      self.instance_type_description['family']
    end

    def required_availability
      vcpu_capability = self.instance_type_description['capabilities'].detect do |capability|
        capability['name'] == 'vCPUs'
      end
      vcpu_capability['value'].to_i * @quantity
    end

    private

    def instance_type_description
      @instance_type_description ||= @cli.describe_instance_type(@instance_type)
    end

    def usage_report
      @usage_report ||= @cli.list_vcpu_usage(family: self.instance_family)
    end
  end
end
