class Deployable
  def step(rank, force: false)
    raise StandardError.new("Creating #{ApplicationController.helpers.friendly_type(@type)}: status failed") if Rails.configuration.lasso_error.present?
    step = Step.find_by(rank: rank)
    return if step.complete? && !force

    step.start!
    step.resource = yield if block_given?
    step.save
    step.complete!
  end

  def random_num()
    # pick a random 4-digit number, return as string
    rand(1000..9999).to_s
  end

  def create_steps!()
    raise NotImplementedError
  end

  def deploy()
    raise NotImplementedError
  end

  def record_rollback()
    KeyValue.set(:recorded_env_vars, {})
    KeyValue.set(:recorded_commands, [])
    Rails.configuration.record_commands = true
    Step.all.order(rank: :desc).each do |step|
      Rails.logger.debug("Step ##{step.rank}")
      step.resource&.destroy_command if step.cleanup_resource
    end
    Rails.configuration.record_commands = false
  end

  def rollback()
    Step.all.order(rank: :desc).each do |step|
      step.destroy if Rails.configuration.lasso_run.present?
    end
  end
end
