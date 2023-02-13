module PreFlight
  class Check < ApplicationRecord
    serialize :view_data

    scope :not_submitted, -> { where(job_submitted_at: nil) }
    scope :pending, -> { where(job_completed_at: nil).where.not(job_submitted_at: nil) }
    scope :all_failed, -> { where.not(passed: true, job_completed_at: nil) }

    def self.all_passed?
      where(passed: true).count == Workflow.preflight_check_count
    end

    def self.all_complete?
      where.not(job_completed_at: nil).count == all.count
    end

    def pending?
      self.job_submitted_at && !self.job_completed_at
    end

    def passed?
      self.job_completed_at && self.passed
    end

    def failed?
      self.job_completed_at && !self.passed
    end

    def submit!
      self.update_attribute(:job_submitted_at, DateTime.now)
      self.job.constantize.perform_later(check_id: self.id)
    end

    def reset!
      self.job_submitted_at = nil
      self.job_completed_at = nil
      self.passed = nil
      self.save
    end
  end
end
