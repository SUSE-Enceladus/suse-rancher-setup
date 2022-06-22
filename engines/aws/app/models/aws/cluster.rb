module AWS
  class Cluster < AWSResource
    attr_accessor :sg_id, :role_arn, :subnet_ids, :k8s_version

    private

    def aws_create
      response = @cli.create_cluster(
        @role_arn,
        @subnet_ids.join(','),
        @sg_id,
        @k8s_version
      )
      self.id = JSON.parse(response)['cluster']['name']
      # self.wait_until(:ACTIVE)
    end

    def aws_destroy
      @cli.delete_cluster(self.id)
      throw(:abort) unless Rails.application.config.lasso_run.present?

      self.wait_until(:DELETING)
      self.wait_until(:not_found)
    end

    def describe_resource
      @cli.describe_cluster(self.id)
    end

    def state_attribute
      @framework_attributes['cluster']['status']
    end
  end
end
