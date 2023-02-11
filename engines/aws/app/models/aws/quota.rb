module AWS
  class Quota < Quota

    def set_cli()
      @cli = AWS::Cli.load()
    end
  end
end
