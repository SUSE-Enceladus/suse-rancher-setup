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

    def supported_instance_type
      @cli = Cli.load
      instance_types = RancherOnEks::ClusterSize.instance_types.values.join(',')
      @cli.describe_instance_type(value, instance_types).present?
    end
  end
end
