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
      when Azure::Engine.routes.url_helpers.edit_region_path
        valid_login?
      when Azure::Engine.routes.url_helpers.region_path
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
  end
end
