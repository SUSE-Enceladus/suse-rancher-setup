module RancherOnAks
  class StepsController < RancherOnAks::ApplicationController
    before_action :load_steps

    def index
      @complete = Step.all_complete?
      @deployable = Step.deployable?
      @resources = Resource.where.associated(:steps)

      if Rails.configuration.lasso_error.present?
        flash[:danger] = Rails.configuration.lasso_error
        @complete = true
      end
      redirect_to(rancher_on_aks.wrapup_path) and return if @complete

      @refresh_timer = 15 unless @deployable
    end

    def deploy
      Rails.configuration.lasso_run = true
      Rails.configuration.lasso_commands = "nil"
      @steps.find_by_rank(0).start!
      RancherOnAks::DeployerJob.perform_later()
      redirect_to(rancher_on_aks.steps_path)
    end

    private

    def load_steps
      if Step.count == 0
        RancherOnAks::Deployment.new.create_steps!
      end
      @steps = Step.all.order(rank: :asc)
    end
  end
end
