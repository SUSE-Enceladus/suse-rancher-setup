module RancherOnEks
  class StepsController < ApplicationController
    before_action :load_steps

    def index
      @deployable = Step.deployable?
      @complete = Step.all_complete?
      @resources = Resource.all
      redirect_to rancher_on_eks.wrapup_path if @complete
      if Rails.application.config.lasso_error != "" && Rails.application.config.lasso_error != "error-cleanup"
        flash.now[:danger] = Rails.application.config.lasso_error
        @deploy_failed = true
        @complete = true
      end
      @refresh_timer = 15 unless (@deployable || @complete)
    end

    def deploy
      Rails.application.config.lasso_run = true
      Rails.application.config.lasso_commands = "nil"
      @steps.find_by_rank(0).start!
      RancherOnEks::DeployerJob.perform_later()
      redirect_to rancher_on_eks.steps_path
    end

    private

    def load_steps
      if Step.count == 0
        RancherOnEks::Deployment.new.create_steps!
      end
      @steps = Step.all.order(rank: :asc)
    end
  end
end
