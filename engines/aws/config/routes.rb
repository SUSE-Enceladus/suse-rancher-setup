AWS::Engine.routes.draw do
  resource :permissions, only: [:show]
  resource :region, only: [:edit, :update]
  resource :step, only: [:new, :create]
  resource :cli, controller: 'cli', only: [:new, :create]
end
