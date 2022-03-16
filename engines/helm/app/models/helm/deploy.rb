require 'json'

module Helm
  class Deployment < Resource
    before_create :helm_create_deployment
    before_destroy :helm_delete_deployment

    def refresh
      @cli ||= Helm::Cli.load
      self.framework_raw_response = @cli.describe_deployment # (self.id)
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def helm_create_deployment
      self.engine = 'Aws'

      @cli ||= Helm::Cli.load
      self.framework_raw_response = @cli.create_deployment
      @response = JSON.parse(self.framework_raw_response)
    end

    # def helm_delete_deployment
    #   @cli ||= Helm::Cli.load
    #   @cli.delete_deployment(self.id)
    # end
  end
end
