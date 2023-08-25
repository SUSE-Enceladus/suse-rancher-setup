module RancherOnAks
  class Fqdn
    include ActiveModel::Model
    include Saveable

    attr_accessor :value

    def initialize(args)
      super(**args)
      @cli = Azure::Interface.load()
    end

    def self.load
      new(
        value: KeyValue.get(:fqdn)
      )
    end

    def save!
      KeyValue.set(:fqdn, @value)
    end

    def hostname
      @value.partition('.').first
    end

    def domain
      @value.partition('.').last
    end

    def to_s
      @value
    end

    def zone_resource_group
      @zone_resource_group ||=
        @cli.find_resource_group_for_dns_zone(zone: self.domain)
    end

    def subdomain_hosted_zone?
      # if the zone is hosted, it has a resource group
      self.zone_resource_group.present?
    end

    def dns_record_exist?
      @cli.describe_dns_record(
        resource_group: self.zone_resource_group,
        record_type: 'A',
        record: self.hostname,
        domain: self.domain
      )
      true
    rescue RestClient::NotFound
      false
    end
  end
end
