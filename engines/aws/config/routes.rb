Aws::Engine.routes.draw do
  resource :cli, controller: 'cli'

  root 'cli#new'
end
