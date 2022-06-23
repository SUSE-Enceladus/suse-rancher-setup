module AWS
  class ApplicationController < ActionController::Base
    before_action :check_access, only: %i[edit]

    helper Rails.application.helpers
    layout 'layouts/application'

    def check_access
      redirect_to('/') unless ApplicationController.helpers.valid_login?
    end
  end
end
