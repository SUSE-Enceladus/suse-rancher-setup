module RancherOnEks
  class SecurityController < RancherOnEks::ApplicationController
    def edit
      @tls_source = TlsSource.load
    end

    def update
      @tls_source = TlsSource.new(self.security_params)
      if @tls_source.save
        flash[:success] = t('flash.tls_source', source: @tls_source.source)
        redirect_to(helpers.next_step_path(rancher_on_eks.edit_security_path))
      else
        flash[:warning] = @tls_source.errors.full_messages
        redirect_to(rancher_on_eks.edit_security_path)
      end
    end

    private

    def security_params
      params.require(:tls_source).permit(:source, :email_address)
    end
  end
end
