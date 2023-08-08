module Azure
  class AzureResource < Resource
    # Abstract class for defining Azure Resources
    after_initialize :set_cli
    attr_reader :cli

    private

    def set_cli
      @cli = Azure::Interface.load()
    end
  end
end
