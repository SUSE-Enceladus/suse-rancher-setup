module Azure
  class PublicIp < AzureResource
    attr_accessor :id

    def self.load(id:)
      instance = self.new(id: id)
      instance.refresh()
      instance
    end

    def ip_address
      @framework_attributes['ipAddress']
    end

    def to_s
      self.ip_address
    end

    def azure_create()
      # resource already exists
      self
    end

    def describe_resource
      @cli.describe_public_ip(id: @id)
    end

    def state_attribute()
      @framework_attributes['provisioningState']
    end
  end
end
