module RancherOnAks
  module AuthorizationHelper
    def can(path)
      result = flow_restriction_checks(path)
      logger.debug "AUTH: #{result ? 'can' : 'cannot'} access #{path}"
      result
    end

    def flow_restriction_checks(path)
      case path
      when '/'
        true
      when '/welcome'
        valid_login?
      when azure.edit_login_path, azure.login_path
        valid_login?
      when azure.edit_region_path, azure.region_path
        valid_login?
      when shirt_size.edit_size_path, shirt_size.size_path
        valid_login? && region_set?
      when rancher_on_aks.edit_fqdn_path, rancher_on_aks.fqdn_path
        valid_login? && region_set?
      when rancher_on_aks.edit_security_path, rancher_on_aks.security_path
        valid_login? && fqdn_set?
      when pre_flight.checks_path, pre_flight.retry_checks_path
        valid_login? && security_set?
      when rancher_on_aks.steps_path, rancher_on_aks.deploy_steps_path
        valid_login? && all_checks_passed?
      when rancher_on_aks.wrapup_path, rancher_on_aks.download_wrapup_path, rancher_on_aks.start_cleanup_path
        valid_login? && setup_done?
      when rancher_on_aks.cleanup_path
        valid_login?
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

    def region_set?
      Azure::Region.load.value.present?
    end

    def fqdn_set?
      RancherOnAks::Fqdn.load.value.present?
    end

    def security_set?
      TlsSource.load.source.present?
    end

    def all_checks_passed?
      PreFlight::Check.all_passed?
    end

    def setup_done?
      Step.all_complete? || Rails.configuration.lasso_error.present?
    end
  end
end
