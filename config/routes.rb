Poirot::Application.routes.draw do
  root 'pages#index'

  resources :activities do
    collection do
      resources :attributes, constraints: { id: /[^\/]+/ } do
        member do
          get 'values'
        end
      end
    end
  end
  resources :log_entries
  resources :notifications
end
