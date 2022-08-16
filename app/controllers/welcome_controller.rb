class WelcomeController < ApplicationController
  before_action :authorize

  def greeting; end
end
