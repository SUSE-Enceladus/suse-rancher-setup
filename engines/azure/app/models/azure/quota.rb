module Azure
  class Quota < Quota

    def limit
      self.usage_report['limit'].to_i
    end

    def usage
      self.usage_report['currentValue'].to_i
    end

    private

    def set_cli()
      @cli = Azure::Interface.load()
    end
  end
end
