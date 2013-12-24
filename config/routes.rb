Poirot::Application.routes.draw do
  root 'pages#index'

  resources :activities do
  end

  resources :log do
  end
end
