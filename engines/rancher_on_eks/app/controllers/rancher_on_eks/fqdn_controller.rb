module RancherOnEks
  class FqdnController < ApplicationController
    def edit
      redirect_to("/") unless ApplicationController.helpers.valid_login?
      @fqdn = Fqdn.load
    end

    def update
      @fqdn = Fqdn.new(self.fqdn_params)
      hosted_zone = @fqdn.subdomain_hosted_zone?
      duplicated_record = @fqdn.dns_record_exist?
      if hosted_zone.present? && !duplicated_record && @fqdn.save
        flash[:success] = t('engines.rancher_on_eks.fqdn.using', fqdn: @fqdn.value)
        redirect_to(helpers.next_step_path(rancher_on_eks.edit_fqdn_path))
      else
        if !hosted_zone
          flash[:warning] = t('flash.no_hosted_zone') + "#{@fqdn.value}."
        elsif duplicated_record
          flash[:warning] = t('flash.duplicated_record') + "#{@fqdn.value}.\n" + t('flash.new_record')
        else
          flash[:warning] = @fqdn.errors.full_messages
        end
        redirect_to(rancher_on_eks.edit_fqdn_path)
      end
    end

    private

    def fqdn_params
      params.require(:fqdn).permit(:value)
    end
  end
end
