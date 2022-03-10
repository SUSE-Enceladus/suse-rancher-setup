module RancherOnEks
  class ApplicationController < ActionController::Base
    helper Rails.application.helpers
    layout 'layouts/application'
  end
end
