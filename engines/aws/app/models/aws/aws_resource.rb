module AWS
  class AWSResource < Resource
    after_initialize :set_cli
    attr_reader :cli

    private

    def set_cli
      @cli = AWS::Cli.load()
    end
  end
end
