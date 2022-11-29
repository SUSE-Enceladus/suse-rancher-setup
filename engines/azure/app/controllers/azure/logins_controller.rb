module Azure
  class LoginsController < Azure::ApplicationController
    def edit
      @credential = Azure::Credential.new()
    end

    def update
      @credential = Azure::Credential.new(login_params)
      if @credential.login
        flash[:success] = t('engines.azure.login.success', service_principal: @credential.app_id)
        redirect_path = helpers.next_step_path(azure.edit_login_path)
      else
        flash[:danger] = t('engines.azure.login.failure', message: @credential.errors.full_messages)
        redirect_path = azure.edit_login_path
      end
      redirect_to(redirect_path)
    end

    private

    def login_params
      params.require(:credential).permit(:app_id, :password, :tenant)
    end
  end
end
