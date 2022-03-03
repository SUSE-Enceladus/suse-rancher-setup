Aws::Engine.routes.draw do
  resource :cli, controller: 'cli'
  resource :credential

  root 'cli#new'
end
