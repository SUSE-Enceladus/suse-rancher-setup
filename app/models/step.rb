class Step < ApplicationRecord
  belongs_to :resource, optional: true

  before_destroy :remove_resource

  def self.deployable?
    Step.count > 0 && Step.where(started_at: nil).count == Step.count
  end

  def self.all_complete?
    Step.count > 0 && Step.where(completed_at: nil).count == 0
  end

  def self.all_deleted?
    Step.count == 0
  end

  def self.resources_left?
    Step.count > 0 && Step.where(completed_at: nil).count > 0
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

  def remove_resource
    if self.cleanup_resource
      self.resource&.destroy
    else
      self.resource&.delete # removes the record without firing callbacks
    end
  end
end
