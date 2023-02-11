module Azure
  class DnsRecord < AzureResource
    attr_accessor :fqdn, :target, :record_type

    def create_command()
      @zone_resource_group = Azure::ResourceGroup.create(
        name: @cli.find_resource_group_for_dns_zone(zone: @fqdn.domain)
      )
      self.creation_attributes = {
        fqdn: @fqdn,
        target: @target,
        record_type: @record_type,
        zone_resource_group: @zone_resource_group
      }
      @cli.create_dns_record(
        resource_group: @zone_resource_group,
        record_type: @record_type,
        record: @fqdn.hostname,
        domain: @fqdn.domain,
        target: @target
      )
      self.id = @fqdn.to_s
      self.refresh()
    end

    def destroy_command()
      @cli.destroy_dns_record(
        resource_group: @zone_resource_group,
        record_type: @record_type,
        record: @fqdn.hostname,
        domain: @fqdn.domain,
      )
    end

    def describe_resource()
      @cli.describe_dns_record(
        resource_group: @zone_resource_group,
        record_type: @record_type,
        record: @fqdn.hostname,
        domain: @fqdn.domain,
      )
    end

    def state_attribute()
      @framework_attributes['provisioningState']
    end
  end
end
