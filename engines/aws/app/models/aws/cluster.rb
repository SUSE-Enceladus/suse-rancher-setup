module AWS
  class Cluster < AWSResource
    attr_accessor :sg_id, :role_arn, :subnet_ids, :k8s_version

    def create_command
      response = @cli.create_cluster(
        @role_arn,
        @subnet_ids.join(','),
        @sg_id,
        @k8s_version
      )
      self.id = JSON.parse(response)['cluster']['name']
      # self.wait_until(:ACTIVE)
    end

    def destroy_command
      @cli.delete_cluster(self.id)
    end

    def wait_for_destroy_command
      self.wait_until(:not_found)
    end

    def to_s
      self.id
    end

    def describe_resource
      @cli.describe_cluster(self.id)
    end

    def state_attribute
      @framework_attributes['cluster']['status']
    end
  end
end
