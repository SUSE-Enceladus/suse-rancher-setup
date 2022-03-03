module Aws
  class CredentialsController < ApplicationController
    before_action :load_credential, only: [:edit, :show]

    def edit
    end

    def show
    end

    def create
      @credential = Credential.new(credential_params())
      if @credential.save
        redirect_to credential_path
      else
        redirect_to edit_credential_path, flash: {
          error: @credential.errors.full_messages
        }
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
