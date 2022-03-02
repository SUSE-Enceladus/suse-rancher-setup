ShirtSize::Engine.routes.draw do
  resource :size

  root 'sizes#new'
end
