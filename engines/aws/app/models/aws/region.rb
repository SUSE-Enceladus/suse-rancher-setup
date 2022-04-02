module AWS
  # singular class for wrapping AWS region selection
  class Region
    include ActiveModel::Model
    include Saveable

    attr_accessor(:value)

    def self.load
      new(
        value: KeyValue.get(:aws_region, 'us-east-1')
      )
    end

    def options
      Cli.load.regions()
    end

    def save!
      KeyValue.set(:aws_region, @value)
    end
  end
end
