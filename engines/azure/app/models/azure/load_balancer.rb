module Azure
  class LoadBalancer < AzureResource
    attr_accessor :name, :resource_group

    def self.load(name: 'kubernetes', resource_group:)
      instance = self.new(name: name, resource_group: resource_group)
      instance.id = name
      instance.refresh()
      instance
    end

    def ready!
      self.wait_until('Succeeded')
    end

    def public_ip
      Azure::PublicIp.load(id: self.public_ip_id)
    end

    def public_ip_id
      @framework_attributes['frontendIPConfigurations'].select{ |c|
        c['loadBalancingRules']
      }.collect{ |c|
        c['publicIPAddress']['id']
      }.first
    end

    def azure_create()
      # resource already exists
      self
    end

    def describe_resource
      @cli.describe_load_balancer(name: @name, resource_group: @resource_group)
    end

    def state_attribute()
      @framework_attributes['provisioningState']
    end
  end
end
