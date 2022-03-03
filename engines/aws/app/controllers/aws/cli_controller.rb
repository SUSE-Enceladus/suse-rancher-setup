module Aws
  class CliController < ApplicationController
    def new; end

    def create
      @args = self.aws_params
      @cli = Cli.load
      @stdout, @stderr = @cli.execute(@args)
      render :show
    end

    private

    def aws_params
      params.permit(:arguments)[:arguments].split(' ')
    end
  end
end
