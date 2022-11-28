module RancherOnAks
  class Engine < ::Rails::Engine
    isolate_namespace RancherOnAks

    initializer 'rancher_on_aks.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper RancherOnAks::AuthorizationHelper
      end
    end
  end
end
