ShirtSize::Engine.routes.draw do
  resource :size, only: [:edit, :update]
end
