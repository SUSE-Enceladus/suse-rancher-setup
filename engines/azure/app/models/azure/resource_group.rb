module Azure
  class ResourceGroup < AzureResource
    attr_accessor :name

    def azure_create()
      self.creation_attributes = {
        name: @name
      }
      response = JSON.parse(@cli.create_resource_group(name: @name))
      self.id = response['id']
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
