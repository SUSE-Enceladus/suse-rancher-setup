module AWS
  class VpcQuotaCheckJob < ApplicationJob
    queue_as :default

    def perform(check_id:)
      check = PreFlight::Check.find(check_id)
      quota = AWS::VpcQuota.new
      check.passed = (quota.availability >= 1) # check passes
      check.job_completed_at = DateTime.now
      check.save
    end
  end
end
