Poirot::Application.routes.draw do
  root 'pages#index'

  resources :activities
  resources :log_entries
  resources :notifications
end
