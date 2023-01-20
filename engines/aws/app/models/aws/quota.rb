module AWS
  class Quota < Quota

    private

    def set_cli()
      @cli = AWS::Cli.load()
    end
  end
end
