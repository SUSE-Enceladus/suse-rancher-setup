Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "welcome#greeting"

  mount Aws::Engine, at: '/aws' if defined?(Aws::Engine)
  mount ShirtSize::Engine, at: '/size' if defined?(ShirtSize::Engine)
end
