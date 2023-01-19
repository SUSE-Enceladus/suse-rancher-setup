RancherOnEks::Engine.routes.draw do
  resource :fqdn, controller: 'fqdn', only: [:edit, :update]

  resource :security, controller: 'security', only: [:edit, :update]

  resources :steps do
    collection do
      post 'deploy'
    end
  end

  resource :wrapup, controller: 'wrapup', only: [:show, :destroy]

  resource :custom_config, only: [:edit, :update]
end
