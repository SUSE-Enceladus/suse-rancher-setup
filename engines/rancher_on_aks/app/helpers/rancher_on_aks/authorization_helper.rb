module RancherOnAks
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
      when azure.edit_login_path, azure.login_path
        valid_login?
      when azure.edit_region_path, azure.region_path
        valid_login?
      when rancher_on_aks.steps_path, rancher_on_aks.deploy_steps_path
        valid_login?
      when rancher_on_aks.wrapup_path
        valid_login? && setup_done?
      else
        false
      end
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
  end
end
