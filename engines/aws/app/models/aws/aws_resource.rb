module AWS
  class AWSResource < Resource
    before_destroy :wait_for_destroy_command

    after_initialize :set_cli
    attr_reader :cli

    def wait_for_destroy_command; true; end

    private

    def set_cli
      @cli = AWS::Cli.load()
    end
  end
end
