class Step < ApplicationRecord
  belongs_to :resource, optional: true

  def self.deployable?
    Step.where(completed_at: nil).count > 0
  end

  def start!
    self.update_attribute(:started_at, DateTime.now)
  end

  def started?
    !!self.started_at
  end

  def complete!
    self.update_attribute(:completed_at, DateTime.now)
  end

  def complete?
    !!self.completed_at
  end
end
