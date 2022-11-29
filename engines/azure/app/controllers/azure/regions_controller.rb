module Azure
  class RegionsController < Azure::ApplicationController
    def edit
      @region = Azure::Region.load
    end

    def update
      @region = Azure::Region.new(region_params)
      if @region.save
        flash[:success] = t('engines.azure.region.using', region: @region.value)
        redirect_to(helpers.next_step_path(azure.edit_region_path))
      else
        flash[:warning] = @region.errors.full_messages
        redirect_to(azure.edit_region_path)
      end
    end

    private

    def region_params
      params.require(:region).permit(:value)
    end
  end
end
