module RancherOnAks
  class Deployment < Deployable
    def create_steps!()
      Step.create!(
        rank: 0,
        duration: 1,
        action: 'Prep'
      )
      Step.create!(
        rank: 1,
        duration: 1,
        action: 'Create a resource group'
      )
      Step.create!(
        rank: 2,
        duration: 1,
        action: 'Create an AKS cluster'
      )
      Step.create!(
        rank: 3,
        duration: 1,
        action: 'Fetch the kubeconfig for the AKS cluster'
      )
      Step.create!(
        rank: 4,
        duration: 1,
        action: 'Deploy the ingress controller'
      )
      Step.create!(
        rank: 5,
        duration: 1,
        action: 'Find the IP address of the load balancer'
      )
      Step.create!(
        rank: 6,
        duration: 1,
        action: 'Create a DNS record for the Rancher server'
      )
      Step.create!(
        rank: 7,
        duration: 1,
        action: 'Deploy the certificate manager'
      )
      Step.create!(
        rank: 8,
        duration: 1,
        action: 'Deploy Rancher'
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
