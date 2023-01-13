module AWS
  class Quota
    def cli
      @cli ||= AWS::Cli.load()
    end
  end
end
