module AWS
  class AWSResource < Resource
    after_initialize :set_cli
    before_create :aws_create
    before_destroy :aws_destroy

    attr_reader :cli

    private

    def set_cli
      @cli = AWS::Cli.load()
    end

    def aws_create
      # Call create functions in AWS CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def aws_destroy
      # call cleanup and destroy functions in AWS CLI
      # must be implemented in child class
      raise NotImplementedError
    end
  end
end
