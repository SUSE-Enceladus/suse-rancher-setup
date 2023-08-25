module Azure
  # singular class for wrapping current subscription ID
  class Subscription
    include ActiveModel::Model
    include Saveable

    attr_accessor(:value)

    def self.load
      new(
        value: KeyValue.get(:azure_subscription)
      )
    end

    def save!
      KeyValue.set(:azure_subscription, @value)
    end
  end
end
