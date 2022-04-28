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

    def valid_url?
      status = URI.open("https://#{@value}").status
      status.include? 'OK'
    rescue
      false
    end
  end
end
