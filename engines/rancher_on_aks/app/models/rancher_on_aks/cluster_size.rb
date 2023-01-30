module RancherOnAks
  # Defines the specifics of the cluster based on t-shirt size
  class ClusterSize < Sizeable
    def self.instance_types
      {
        'small' => %w(Standard_D2as_v5 Standard_D2s_v5) ,
        'medium' => %w(Standard_D4as_v5 Standard_D4s_v5),
        'large' => %w(Standard_D8as_v5 Standard_D8s_v5)
      }
    end

    def instance_type
      @region = Azure::Region.load
      regional_instance_types = @region.available_instance_types
      sized_instance_types = self.instance_types[@size]
      (sized_instance_types & regional_instance_types).first
    end

    def instance_count
      3
    end

    def zones_count
      3
    end
  end
end
