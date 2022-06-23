class ApplicationController < ActionController::Base
  layout 'layouts/application'
  add_flash_types :success, :info, :warning, :danger

  before_action :check_access, only: %i[show edit greeting]

  def check_access
    redirect_to('/') unless ApplicationController.helpers.valid_login?
  end
end
