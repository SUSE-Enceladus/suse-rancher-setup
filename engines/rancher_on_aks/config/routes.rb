RancherOnAks::Engine.routes.draw do
  resources :steps do
    collection do
      post 'deploy'
    end
  end
  resource :wrapup, controller: 'wrapup', only: [:show, :destroy]
end
