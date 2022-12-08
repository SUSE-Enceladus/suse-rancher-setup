module RancherOnAks
  class FqdnController < RancherOnAks::ApplicationController
    def edit
      @fqdn = Fqdn.load
    end

    def update
      @fqdn = RancherOnAks::Fqdn.new(self.fqdn_params)
      unless @fqdn.subdomain_hosted_zone?
        flash[:warning] = t('flash.no_hosted_zone', domain: @fqdn.domain)
        redirect_to(rancher_on_aks.edit_fqdn_path) and return
      end

      if @fqdn.dns_record_exist?
        flash[:warning] = t('flash.duplicate_record', fqdn: @fqdn.value)
        redirect_to(rancher_on_aks.edit_fqdn_path) and return
      end

      if @fqdn.save
        flash[:success] = t('flash.using_fqdn', fqdn: @fqdn.value)
        redirect_to(helpers.next_step_path(rancher_on_aks.edit_fqdn_path))
      else
        flash[:warning] = @fqdn.errors.full_messages
        redirect_to(rancher_on_aks.edit_fqdn_path)
      end
    end

    private

    def fqdn_params
      params.require(:fqdn).permit(:value)
    end
  end
end
