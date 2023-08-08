module Azure
  class ResourceGroup < AzureResource
    attr_accessor :name

    def to_s
      @name
    end

    def create_command()
      self.creation_attributes = {
        name: @name
      }
      self.id = @name
      return if @cli.resource_group_exists?(name: @name)

      @cli.create_resource_group(name: @name)
      self.refresh()
    end

    def ready!
      self.wait_until('Succeeded')
    end

    def destroy_command()
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
