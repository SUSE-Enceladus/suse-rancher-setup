module AWS
  class DnsRecord < AWSResource
    attr_accessor :fqdn, :target, :record_type

    def hosted_zone
      @fqdn.split('.')[1..].join('.')
    end

    private

    def aws_create
      hosted_zone_id = @cli.get_hosted_zone_id(self.hosted_zone())
      response = @cli.create_dns_record(
        hosted_zone_id, @fqdn, @target, @record_type
      )
      self.id = @fqdn
      self.refresh()
    end

    def aws_destroy
      # @cli.release_address(self.id)
      # self.wait_until(:not_found)
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
