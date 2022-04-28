module AWS
  class CredentialsController < ApplicationController
    before_action :load_credential, only: [:edit, :show]

    def edit; end

    def update
      @credential = Credential.new(self.credential_params)
      valid_credentials = @credential.valid_credentials? self.credential_params
      if valid_credentials && @credential.save
        flash[:success] = t(
          'engines.aws.credentials.using',
          key_id: @credential.aws_access_key_id
        )
        redirect_to(helpers.next_step_path(aws.edit_credential_path))
      else
        flash[:warning] = @credential.errors.full_messages if valid_credentials
        flash[:warning] = t('flash.invalid_credentials') unless valid_credentials
        redirect_to(aws.edit_credential_path)
      end
    end

    private

    def load_credential
      @credential = Credential.load
    end

    def credential_params
      params.require(:credential).permit(:aws_access_key_id, :aws_secret_access_key)
    end
  end
end
