module Aws
  class RegionsController < ApplicationController
    def edit
      @region = Region.load
    end

    def update
      @region = Region.new(region_params)
      if @region.save
        render :show
      else
        redirect_to edit_region_path, flash: {
          error: @region.errors.full_messages
        }
      end
    end

    private

    def region_params
      params.require(:region).permit(:value)
    end
  end
end
