require 'open-uri'

module RancherOnEks
  class Fqdn
    include ActiveModel::Model
    include Saveable

    attr_accessor :value

    def self.load
      new(
        value: KeyValue.get(:fqdn, '')
      )
    end

    def save!
      KeyValue.set(:fqdn, @value)
    end

    def subdomain_hosted_zone?
      hosted_zone = @value.partition(".").last
      @cli = AWS::Cli.load
      @cli.get_hosted_zone_id hosted_zone
    rescue
      false
    end

    def dns_record_exist?
      domain = @value.partition(".").last
      @cli = AWS::Cli.load
      dns_records = @cli.list_dns_records(domain)
      duplicated_record = dns_records.select {|dns_record| dns_record['Name'] == (@value + ".")}
      return duplicated_record.present?
    end
  end
end
