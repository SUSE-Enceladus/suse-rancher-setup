PreFlight::Engine.routes.draw do
  resources :checks do
    get 'retry', on: :collection
  end
end
