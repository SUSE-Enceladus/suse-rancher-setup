module Aws
  class StepsController < ApplicationController
    def new; end

    def create
      @step = steps_params()[:step]
      @cli = Cli.load
      @output = @cli.send(@step)
      render :show
    end

    private

      def steps_params
        params.permit(:step)
      end
  end
end
