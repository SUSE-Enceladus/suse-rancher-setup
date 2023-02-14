module AWS
  class DnsRecord < AWSResource
    attr_accessor :fqdn, :target, :record_type

    def hosted_zone
      fqdn = RancherOnEks::Fqdn.load()
      fqdn.value.split('.')[1..].join('.')
    end

    def create_command
      hosted_zone_id = @cli.get_hosted_zone_id(self.hosted_zone())
      self.creation_attributes = {
        hosted_zone_id: hosted_zone_id,
        target: @target,
        record_type: @record_type,
        fqdn: @fqdn
      }
      response = @cli.create_dns_record(
        hosted_zone_id, @fqdn, @target, @record_type
      )
      self.id = @fqdn
      self.refresh()
    end

    def destroy_command
      @cli.delete_dns_record(
        @hosted_zone_id, @fqdn, @target, @record_type
      )
    end

    def describe_resource
      @cli.list_dns_records(self.hosted_zone()).find do |record|
        return record['Name'] == @fqdn
      end
      {}
    end

    def state_attribute
      if @framework_attributes['Name']
        'available'
      else
        'not_found'
      end
    end
  end
end
