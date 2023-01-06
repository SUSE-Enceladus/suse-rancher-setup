module AWS
  class PermissionsController < AWS::ApplicationController
    def show
      @metadata = AWS::Metadata.load()
      @passed = false
      @arn = @metadata.policy_source_arn()
      @permissions = AWS::Permissions.new(
        source_policy_file: Rails.configuration.aws_iam_source_policy_path,
        arn: @arn
      )
      @passed = Rails.configuration.permissions_passed || @permissions.passed?
    rescue AWS::MissingInstanceProfile
      flash[:danger] = t('flash.missing_instance_profile')
    rescue StandardError => error
      flash[:danger] = t('error', message: error.message)
    end
  end
end
