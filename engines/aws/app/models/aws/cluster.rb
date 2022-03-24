module Aws
  class Cluster < AwsResource
    attr_accessor :sg_id, :role_arn, :subnet_ids

    private

    def aws_create
      response = @cli.create_cluster(@role_arn, @subnet_ids.join(','), @sg_id)
      self.id = JSON.parse(response)['cluster']['name']
      # self.wait_until(:ACTIVE)
    end

    def aws_destroy(f=nil)
      @cli.delete_cluster(self.id, f)
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
