module Azure
  class AzureResource < Resource
    # Abstract class for defining Azure Resources
    after_initialize :set_cli
    before_create :azure_create
    before_destroy :azure_destroy

    attr_reader :cli

    private

    def set_cli
      @cli = Azure::Cli.load()
    end

    def azure_create
      # Call create functions in Azure::Cli
      # must be implemented in child class
      raise NotImplementedError
    end

    def azure_destroy
      # call cleanup and destroy functions in Azure::Cli
      # must be implemented in child class
      raise NotImplementedError
    end
  end
end
