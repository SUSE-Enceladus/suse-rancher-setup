# frozen_string_literal: true

# Authorize access to steps
module AuthorizationHelper
  def can(path)
    result = flow_restriction_checks(path)
    logger.debug "AUTH: #{result ? 'can' : 'cannot'} access #{path}"
    result
  end

  def flow_restriction_checks(path)
    case path
    when  "/"
      true
    when '/welcome'
      valid_login?
    when AWS::Engine.routes.url_helpers.permissions_path
      valid_login?
    when AWS::Engine.routes.url_helpers.edit_region_path
      valid_login? && has_permissions?
    when ShirtSize::Engine.routes.url_helpers.edit_size_path
      valid_login? && region_set?
    when RancherOnEks::Engine.routes.url_helpers.edit_fqdn_path
      valid_login? && region_set?
    when RancherOnEks::Engine.routes.url_helpers.steps_path
      valid_login? && fqdn_set?
    when RancherOnEks::Engine.routes.url_helpers.wrapup_path
      valid_login? && Step.all_complete?
    else
      false
    end
  end

  def region_set?
    region = AWS::Region.load
    region.value.present?
  end

  def fqdn_set?
    fqdn = RancherOnEks::Fqdn.load
    fqdn.value.present?
  end

  def valid_login?
    Rails.application.config.lasso_logged
  end

  def has_permissions?
    return true if Rails.application.config.permissions_passed

    metadata = AWS::Metadata.load()
    permissions = AWS::Permissions.new(
      source_policy_file: Rails.application.config.aws_iam_source_policy_path,
      arn: metadata.policy_source_arn()
    )
    Rails.application.config.permissions_passed = permissions.passed?
    Rails.application.config.permissions_passed
  rescue
    false
  end
end
