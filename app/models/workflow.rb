# Singleton class shortcut to the configured worflow engine
class Workflow
  def self.method_missing(m, *args, &block)
    workflow = Rails.configuration.workflow.constantize
    workflow.send(m, *args, &block)
  end
end
