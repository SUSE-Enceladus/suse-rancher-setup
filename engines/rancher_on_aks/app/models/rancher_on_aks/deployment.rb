module RancherOnAks
  class Deployment < Deployable
    def create_steps!()
      Step.create!(
        rank: 0,
        duration: 1,
        action: 'Prep'
      )
    end

    def deploy()
      step(0, force: true) do
        KeyValue.set('tag_scope', "suse-rancher-setup-#{self.random_num()}")
        nil
      end
      Rails.configuration.lasso_deploy_complete = true
    end
  end
end
