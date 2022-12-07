module Azure
  class ResourceGroup < AzureResource
    attr_accessor :name

    def to_s
      @name
    end

    def azure_create()
      self.creation_attributes = {
        name: @name
      }
      @cli.create_resource_group(name: @name)
      self.id = @name
      self.refresh()
    end

    def ready!
      self.wait_until('Succeeded')
    end

    def azure_destroy()
      @cli.destroy_resource_group(name: @name)
    end

    def describe_resource()
      @cli.describe_resource_group(name: @name)
    end

    def state_attribute()
      @framework_attributes['properties']['provisioningState']
    end
 end
end
