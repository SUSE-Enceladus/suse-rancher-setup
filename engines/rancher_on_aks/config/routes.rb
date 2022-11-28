RancherOnAks::Engine.routes.draw do
  resource :wrapup, controller: 'wrapup', only: [:show, :destroy]
end
