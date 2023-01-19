require 'open-uri'

module RancherOnEks
  class Fqdn
    include ActiveModel::Model
    include Saveable

    attr_accessor :value

    def initialize(args)
      super(**args)
      @cli = AWS::Cli.load()
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

    def subdomain_hosted_zone?
      @cli.get_hosted_zone_id(self.domain)
    rescue
      false
    end

    def dns_record_exist?
      dns_records = @cli.list_dns_records(self.domain)
      duplicated_record = dns_records.select { |dns_record|
        dns_record['Name'] == (@value + ".")
      }
      duplicated_record.present?
    end
  end
end
