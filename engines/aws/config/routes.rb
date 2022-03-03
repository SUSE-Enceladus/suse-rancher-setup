Aws::Engine.routes.draw do
  resource :cli, controller: 'cli'
  resource :credential
  resource :step
  resource :region
end
