Poirot::Application.routes.draw do
  devise_for :users, :skip => [:registrations]
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end
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
