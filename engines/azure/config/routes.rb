Azure::Engine.routes.draw do
  resource :region, only: [:edit, :update]
end
