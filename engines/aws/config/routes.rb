Aws::Engine.routes.draw do
  resource :credential, only: [:edit, :update]
  resource :region, only: [:edit, :update]
  resource :step, only: [:new, :create]
  resource :cli, controller: 'cli', only: [:new, :create]
end
