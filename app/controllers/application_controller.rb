class ApplicationController < ActionController::Base
  layout 'layouts/application'
  add_flash_types :success, :info, :warning, :danger

  before_action :current_user
  before_action :authorize

  def current_user
    @current_user ||= User.load(session[:authorized_at])
  end

  def authorize
    unless @current_user.is_authorized?
      flash[:danger] = t('flash.login_required')
      redirect_to(main_app.root_path) and return
    end
    unless helpers.can(request.path)
      flash[:danger] = t('flash.not_authorized')
      redirect_back(fallback_location: main_app.root_path) and return
    end
  end
end
