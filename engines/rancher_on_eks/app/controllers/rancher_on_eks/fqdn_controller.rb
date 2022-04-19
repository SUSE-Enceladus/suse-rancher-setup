module RancherOnEks
  class FqdnController < ApplicationController
    def edit
      @fqdn = Fqdn.load
    end

    def update
      @fqdn = Fqdn.new(self.fqdn_params)
      available = @fqdn.dns_available?
      if available && @fqdn.save
        flash[:success] = t('engines.rancher_on_eks.fqdn.using', fqdn: @fqdn.value)
        redirect_to(helpers.next_step_path(rancher_on_eks.edit_fqdn_path))
      else
        flash[:warning] = @fqdn.errors.full_messages if available
        flash[:warning] = "Can not resolve specified FQDN: #{@fqdn.value}." unless available

        redirect_to(rancher_on_eks.edit_fqdn_path)
      end
    end

    private

    def fqdn_params
      params.require(:fqdn).permit(:value)
    end
  end
end
