require "cheetah"

module Aws
  class CliController < ApplicationController
    def new; end

    def create
      @cmd = ['aws'] + aws_params()[:arguments]
      @credential = Credential.load
      @stdout, @stderr = Cheetah.run(
        @cmd,
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => @credential.aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => @credential.aws_secret_access_key
        }
      )
      render :show
    end

    private

    def aws_params
      params.require(:arguments)
      params[:arguments] = params[:arguments].split(' ')
      return params
    end

  end
end
