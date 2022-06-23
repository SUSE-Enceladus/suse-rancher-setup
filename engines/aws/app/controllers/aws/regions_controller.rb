module AWS
  class RegionsController < ApplicationController
    def edit
      @region = Region.load
    end

    def update
      @region = Region.new(region_params)
      supported_instances = @region.supported_instance_types
      if supported_instances.present? && @region.save
        flash[:success] = t('engines.aws.region.using', region: @region.value)
        redirect_to(helpers.next_step_path(aws.edit_region_path))
      else
        flash[:warning] = @region.errors.full_messages if supported_instances
        flash[:danger] = t('engines.aws.region.not_available', region: @region.value) unless supported_instances

        redirect_to(aws.edit_region_path)
      end
    end

    private

    def region_params
      params.require(:region).permit(:value)
    end
  end
end
