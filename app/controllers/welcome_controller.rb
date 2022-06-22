class WelcomeController < ApplicationController
  def greeting
    redirect_to(login_index_path) unless ApplicationController.helpers.valid_login?
  end
end
