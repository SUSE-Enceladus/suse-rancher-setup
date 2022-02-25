require "cheetah"

module Aws
  class CliController < ApplicationController
    layout 'layouts/application'

    def new; end

    def create
      @cmd = ['aws'] + aws_params()[:arguments]
      @stdout, @stderr = Cheetah.run(*@cmd, :stdout => :capture, :stderr => :capture)
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
