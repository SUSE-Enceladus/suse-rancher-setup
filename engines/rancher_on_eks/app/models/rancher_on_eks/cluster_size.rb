module RancherOnEks
  # Defines the specifics of the cluster based on t-shirt size
  class ClusterSize < Sizeable

    TYPES_FOR_SIZE = {
      small: 'm5a.large',
      medium: 'm5a.xlarge',
      large: 'm5a.2xlarge'
    }

    def instance_type
      @region = AWS::Region.load
      supported_instance_types = @region.supported_instance_types
      supported_instance_types = supported_instance_types.split(',')
      supported_instance_types[TYPES.find_index(@size)]
    end

    def self.instance_types
      TYPES_FOR_SIZE
    end

    def instance_count
      3
    end

    def zones_count
      3
    end
  end
end
