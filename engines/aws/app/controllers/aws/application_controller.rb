module Aws
  class ApplicationController < ActionController::Base
    helper Rails.application.helpers
    layout 'layouts/application'
  end
end
