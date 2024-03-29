class LoginController < ApplicationController
  skip_before_action :authorize

  def show
    if @current_user.is_authorized?
      redirect = helpers.next_step_path(login_path)
      redirect_to(redirect)
    end
    @csp_login_info = helpers.csp_key()
  end

  def update
    user = User.new(self.login_params)
    session[:authorized_at] = user.authorize
    redirect_path = helpers.next_step_path(login_path)
    unless user.is_authorized?
      flash[:danger] = user.errors.full_messages.join("\n").truncate(1000)
      redirect_path = root_path
    end
    redirect_to(redirect_path)
  end

  private

  def login_params
    params.require(:user).permit(:username, :password)
  end
end
