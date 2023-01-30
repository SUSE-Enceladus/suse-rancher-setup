return unless defined?(PreFlight::Engine)

module AWS
  class VpcQuotaCheckJob < ApplicationJob
    queue_as :default

    def perform(check_id:)
      check = PreFlight::Check.find(check_id)
      quota = AWS::VpcQuota.new
      check.passed = quota.sufficient_capacity?
      check.view_data = {
        region: AWS::Region.load.value
      }
      check.job_completed_at = DateTime.now
      check.save
    end
  end
end
