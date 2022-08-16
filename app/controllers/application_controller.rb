class ApplicationController < ActionController::Base
  layout 'layouts/application'
  add_flash_types :success, :info, :warning, :danger

  before_action :current_user
  before_action :check_access, only: %i[greeting]

  def current_user
    @current_user ||= User.load
  end

  def check_access
    redirect_to('/') unless @current_user.is_authorized?
  end
end
