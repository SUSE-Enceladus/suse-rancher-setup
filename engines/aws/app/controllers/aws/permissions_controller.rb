module AWS
  class PermissionsController < AWS::ApplicationController
    def show
      @metadata = AWS::Metadata.load()
      @permissions = AWS::Permissions.new(
        source_policy_file: Rails.configuration.aws_iam_source_policy_path,
        arn: @metadata.policy_source_arn()
      )
    rescue StandardError => error
      flash[:danger] = t('error', message: error.message)
    end
  end
end
