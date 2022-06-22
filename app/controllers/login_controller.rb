class LoginController < ApplicationController
  before_action :set_rancher_setup_login, only: %i[ index update ]

  def index
    if ApplicationController.helpers.valid_login?
      redirect = helpers.next_step_path(login_index_path)
      redirect_to(redirect)
    end
    @csp_login_info = 'aws' # currently AWS only, planning for other CSPs
  end

  # PATCH/PUT /rancher_setup_logins/1 or /rancher_setup_logins/1.json
  def update
    @login = Login.new(self.rancher_setup_login_params)
    valid_pass, err = _verify_credentials
    redirect_path = nil
    if valid_pass
      Rails.application.config.lasso_logged = true
      redirect_path = helpers.next_step_path(login_index_path)
    else
      flash[:danger] = "Could not verify your login credentials #{err}" if err.present?
      flash[:danger] = "You can not access the setup" if err.nil?

      redirect_path = '/'
    end
    redirect_to(redirect_path)
  end

  private
    def set_rancher_setup_login
      @rancher_setup_login = Login.load
    end

    # Only allow a list of trusted parameters through.
    def rancher_setup_login_params
      params.require(:login).permit(:username, :password)
    end

    def _verify_credentials
      credentials = File.open(Rails.application.config.lasso_nginx_pass_file, 'r') {|f| f.readlines}
      credentials.each do |credential|
        username, pass = credential.split(":")
        if username == @login.username
          apr_scope = pass.reverse.split('$', 2).collect(&:reverse).reverse[0]
          # salt for the password is between $apr1$ and the following $
          # as a Base64-encoded binary value - max 8 chars
          salt = apr_scope.reverse.split('$', 2).collect(&:reverse).reverse[1]
          open_ssl_command = %W(openssl passwd -apr1 -salt #{salt} #{@login.password})
          stdout, stderr = Cheetah.run(
            open_ssl_command,
            stdout: :capture,
            stderr: :capture,
            logger: Rails.logger
          )
          return stdout == pass, stderr
        else
          return false, nil
        end
      end
    rescue Cheetah::ExecutionFailed => err
      return false, err.stderr
    rescue StandardError => err
      return false, err.message
    end
end
