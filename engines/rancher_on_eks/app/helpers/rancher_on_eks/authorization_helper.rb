module RancherOnEks
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
      when RancherOnEks::Engine.routes.url_helpers.edit_custom_config_path
        valid_login?
      when RancherOnEks::Engine.routes.url_helpers.custom_config_path
        valid_login?
      when AWS::Engine.routes.url_helpers.permissions_path
        valid_login?
      when AWS::Engine.routes.url_helpers.edit_region_path
        valid_login? && has_permissions?
      when AWS::Engine.routes.url_helpers.region_path
        valid_login? && has_permissions?
      when ShirtSize::Engine.routes.url_helpers.edit_size_path
        valid_login? && region_set?
      when ShirtSize::Engine.routes.url_helpers.size_path
        valid_login? && region_set?
      when RancherOnEks::Engine.routes.url_helpers.edit_fqdn_path
        valid_login? && region_set?
      when RancherOnEks::Engine.routes.url_helpers.fqdn_path
        valid_login? && region_set?
      when RancherOnEks::Engine.routes.url_helpers.steps_path
        valid_login? && fqdn_set?
      when RancherOnEks::Engine.routes.url_helpers.deploy_steps_path
        valid_login? && fqdn_set?
      when RancherOnEks::Engine.routes.url_helpers.wrapup_path
        valid_login? && setup_done?
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

    def current_user
      @current_user ||= User.load
    end

    def valid_login?
      current_user.is_authorized?
    end

    def setup_done?
      Rails.configuration.lasso_deploy_complete || Rails.configuration.lasso_error.present?
    end

    def has_permissions?
      return true if Rails.configuration.permissions_passed

      metadata = AWS::Metadata.load()
      permissions = AWS::Permissions.new(
        source_policy_file: Rails.configuration.aws_iam_source_policy_path,
        arn: metadata.policy_source_arn()
      )
      Rails.configuration.permissions_passed = permissions.passed?
    rescue
      false
    end
  end
end
