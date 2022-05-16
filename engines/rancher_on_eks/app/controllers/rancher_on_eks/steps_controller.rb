module RancherOnEks
  class StepsController < ApplicationController
    before_action :load_steps

    def index
      @deployable = Step.deployable?
      @complete = Step.all_complete?
      redirect_to rancher_on_eks.wrapup_path if @complete

      @refresh_timer = 15 unless (@deployable || @complete)
    end

    def deploy
      Rails.application.config.lasso_run = true
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
