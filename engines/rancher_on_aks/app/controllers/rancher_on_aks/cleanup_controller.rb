module RancherOnAks
  class CleanupController < RancherOnAks::ApplicationController

    def start
      Rails.configuration.lasso_error = nil
      RancherOnAks::CleanupJob.perform_later()
      redirect_to(rancher_on_aks.cleanup_path)
    end

    def show
      @resources = Resource.where.associated(:steps)
      @complete = @resources.count == 0
      render(:success) and return if @complete

      if Rails.configuration.lasso_error.present?
        flash.now[:danger] = Rails.configuration.lasso_error
        render(:failed) and return
      end

      @refresh_timer = 15
    end
  end
end
