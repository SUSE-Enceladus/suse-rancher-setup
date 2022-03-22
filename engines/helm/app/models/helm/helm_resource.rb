module Helm
  class HelmResource < Resource
    after_initialize :set_cli
    before_create :helm_create
    before_destroy :helm_destroy

    attr_reader :helm, :kubectl

    private

    def set_cli
      @helm = Helm::Cli.load
      @kubectl = K8s::Cli.load
    end

    def helm_create
      # Call create functions in Helm CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def helm_destroy
      # call cleanup and destroy functions in Helm CLI
      # must be implemented in child class
      raise NotImplementedError
    end

  end
end
