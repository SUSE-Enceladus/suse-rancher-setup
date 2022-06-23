Rails.application.routes.draw do
  resources :login, only: [:index, :update]
  # Defines the root path route ("/")
  root "login#index"
  get "/welcome", to: "welcome#greeting"

  # 1 Deployable solution should be mounted
  mount RancherOnEks::Engine, at: '/deploy' if defined?(RancherOnEks::Engine)
  # Required CSP engines should be mounted
  mount AWS::Engine, at: '/aws' if defined?(AWS::Engine)
  # Configuration options, as needed
  mount ShirtSize::Engine, at: '/size' if defined?(ShirtSize::Engine)
end
