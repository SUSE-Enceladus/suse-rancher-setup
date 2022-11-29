Rails.application.routes.draw do
  resource :login, controller: 'login', only: [:show, :update]
  # Defines the root path route ("/")
  root "login#show"
  get "/welcome", to: "welcome#greeting"

  # 1 Deployable solution should be mounted
  mount RancherOnEks::Engine, at: '/deploy' if defined?(RancherOnEks::Engine)
  mount RancherOnAks::Engine, at: '/deploy' if defined?(RancherOnAks::Engine)
  # Required CSP engines should be mounted
  mount AWS::Engine, at: '/aws' if defined?(AWS::Engine)
  mount Azure::Engine, at: '/azure' if defined?(Azure::Engine)
  # Configuration options, as needed
  mount ShirtSize::Engine, at: '/size' if defined?(ShirtSize::Engine)
end
