RancherOnEks::Engine.routes.draw do
  resources :steps do
    collection do
      post 'deploy'
    end
  end
end
