RancherOnAks::Engine.routes.draw do
  resource :fqdn, controller: 'fqdn', only: [:edit, :update]
  resources :steps do
    collection do
      post 'deploy'
    end
  end
  resource :wrapup, controller: 'wrapup', only: [:show, :destroy]
end
