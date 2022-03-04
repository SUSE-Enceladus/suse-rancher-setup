module Aws
  class StepsController < ApplicationController
    before_action :load_cli

    def new; end

    def create
      @step = step_param
      @cli.send(@step)
      render :show
    end

    private

    def load_cli
      @cli = Cli.load
    end

    def step_param
      params.permit(:step)[:step]
    end
  end
end
