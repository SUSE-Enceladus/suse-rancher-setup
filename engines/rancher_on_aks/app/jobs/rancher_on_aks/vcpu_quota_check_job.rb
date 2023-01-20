module RancherOnAks
  class VcpuQuotaCheckJob < ApplicationJob
    queue_as :default

    def perform(check_id:)
      check = PreFlight::Check.find(check_id)
      cluster_size = RancherOnAks::ClusterSize.new
      quota = Azure::VcpuQuota.new(
        instance_type: cluster_size.instance_type,
        quantity: cluster_size.instance_count
      )
      check.passed = quota.sufficient_capacity?
      check.view_data = {
        instance_family: quota.instance_family,
        vcpu_count: quota.required_availability,
        region: Azure::Region.load().value
      }
      check.job_completed_at = DateTime.now
      check.save
    end
  end
end
