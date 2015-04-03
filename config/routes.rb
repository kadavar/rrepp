require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  resources :projects, only: [:index, :new, :create, :destroy]
  resources :project_logs, only: [:index, :show]
  resources :project_configs

  root to: 'landing#index'
end


