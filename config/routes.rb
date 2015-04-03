require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  resources :project, only: [:index, :new, :create, :destroy]
  resources :project_log, only: [:index, :show]
  resources :project_config

  root to: 'landing#index'
end


