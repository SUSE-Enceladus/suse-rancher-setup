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

    def dns_available?
      system("ping -c 1 -W 1 #{@value}")
    end
  end
end
