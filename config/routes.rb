Poirot::Application.routes.draw do
  devise_for :users, skip: [:registrations], controllers: { omniauth_callbacks: "omniauth_callbacks" }
  guisso_for :user

  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end
  root 'pages#index'

  resources :activities, only: [:index] do
    collection do
      get ':date/:id' => :show
      resources :attributes, constraints: { id: /[^\/]+/ }, type: 'activity' do
        member do
          get 'values'
        end
      end
    end
  end
  resources :log_entries, only: [:index] do
    collection do
      get ':date/:id' => :show
      resources :attributes, constraints: { id: /[^\/]+/ }, type: 'logentry' do
        member do
          get 'values'
        end
      end
    end
  end
  resources :notifications
  resources :users
end
