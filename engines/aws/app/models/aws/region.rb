module AWS
  # singular class for wrapping AWS region selection
  class Region
    include ActiveModel::Model
    include Saveable

    attr_accessor(:value)

    def self.load
      new(
        value: KeyValue.get(:region, 'us-east-1')
      )
    end

    def options
      cli = Cli.load
      cli.region = @value
      cli.regions()
    end

    def save!
      KeyValue.set(:region, @value)
    end

    def supported_instance_types
      @cli = Cli.load
      instance_types = RancherOnEks::ClusterSize.instance_types.values.join(',')
      if @cli.describe_instance_type_offerings(value, instance_types).empty?
        [4, 5].each do |instance_type_number|
          instance_types = "m#{instance_type_number}.large,m#{instance_type_number}.xlarge,m#{instance_type_number}.2xlarge"
          return instance_types if @cli.describe_instance_type_offerings(value, instance_types).present?
        end
        nil
      else
        instance_types
      end
    rescue
      nil
    end
  end
end
