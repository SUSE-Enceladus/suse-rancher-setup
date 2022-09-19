module RancherOnEks
  class Engine < ::Rails::Engine
    isolate_namespace RancherOnEks

    initializer 'rancher_on_eks.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper RancherOnEks::AuthorizationHelper
      end
    end
  end
end
