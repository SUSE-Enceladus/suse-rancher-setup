Rails.application.routes.draw do
  mount Azure::Engine => "/azure"
end
