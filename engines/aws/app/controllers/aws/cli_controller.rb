module Aws
  class CliController < ApplicationController
    def new; end

    def create
      @args = aws_params()[:arguments]
      @cli = Cli.load
      @stdout, @stderr = @cli.execute(@args)
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
