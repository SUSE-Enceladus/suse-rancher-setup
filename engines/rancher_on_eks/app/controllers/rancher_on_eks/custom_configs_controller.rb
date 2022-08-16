module RancherOnEks
  class CustomConfigsController < RancherOnEks::ApplicationController
    def edit
      @custom_config = CustomConfig.load
    end

    def update
      @custom_config = CustomConfig.new(self.custom_config_params)
      if @custom_config.save
        flash[:success] = t('engines.rancher_on_eks.custom_configs.success')
        redirect_to('/')
      else
        flash[:warning] = @custom_config.errors.full_messages
        redirect_to(rancher_on_eks.edit_custom_config_path)
      end
    end

    private

    def custom_config_params
      params.require(:custom_config).permit(
        RancherOnEks::CustomConfig.attribute_names
      )
    end
  end
end
