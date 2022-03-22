class ApplicationController < ActionController::Base
  layout 'layouts/application'
  add_flash_types :success, :info, :warning, :danger
end
