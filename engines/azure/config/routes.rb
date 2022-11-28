Azure::Engine.routes.draw do
  resource :region, only: [:edit, :update]
  resource :login, only: [:edit, :update]
end
