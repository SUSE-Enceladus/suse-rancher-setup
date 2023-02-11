module Helm
  class HelmResource < Resource
    after_initialize :set_cli
    attr_reader :helm, :kubectl

    def ready!
      self.wait_until(:deployed)
      self
    end

    private

    def set_cli
      @helm = Helm::Cli.load
      @kubectl = K8s::Cli.load
    end

    def create_command
      # Call create functions in Helm CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def destroy_command
      # call cleanup and destroy functions in Helm CLI
      # must be implemented in child class
      raise NotImplementedError
    end
  end
end
