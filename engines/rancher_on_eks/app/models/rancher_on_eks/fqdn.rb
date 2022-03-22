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
  end
end
