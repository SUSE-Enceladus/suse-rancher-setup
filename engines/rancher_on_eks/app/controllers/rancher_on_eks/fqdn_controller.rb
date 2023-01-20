module RancherOnEks
  class FqdnController < RancherOnEks::ApplicationController
    def edit
      @fqdn = Fqdn.load
    end

    def update
      @fqdn = Fqdn.new(self.fqdn_params)
      hosted_zone = @fqdn.subdomain_hosted_zone?
      duplicated_record = @fqdn.dns_record_exist?
      if hosted_zone.present? && !duplicated_record && @fqdn.save
        flash[:success] = t('flash.using_fqdn', fqdn: @fqdn.value)
        redirect_to(helpers.next_step_path(rancher_on_eks.edit_fqdn_path))
      else
        if !hosted_zone
          flash[:warning] = t('flash.no_hosted_zone', domain: @fqdn.domain)
        elsif duplicated_record
          flash[:warning] = t('flash.duplicate_record', fqdn: @fqdn.value)
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
