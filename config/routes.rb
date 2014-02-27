Poirot::Application.routes.draw do
  root 'pages#index'

  resources :activities do
  end

  resources :log_entries do
  end
end
