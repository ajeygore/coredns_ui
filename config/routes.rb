Rails.application.routes.draw do
  resources :api_tokens, only: %i[index new destroy]
  resources :dns_zones do
    resources :dns_records
  end

  namespace :api do
    namespace :v1 do
      post 'zones/create_subdomain', to: 'zones#create_subdomain'
      post 'zones/create_acme_challenge', to: 'zones#create_acme_challenge'
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest

  get '/dns_zones/:id/refresh' => 'dns_zones#refresh', as: :refresh
  # Defines the root path route ("/")
  root 'dns_zones#index'

  # OmniAuth routes
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'logout', to: 'sessions#destroy', as: 'logout'
  get 'login', to: 'application#login', as: 'login'
end
