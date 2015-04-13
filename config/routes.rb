require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  resources :projects, only: [:index, :new, :create, :destroy] do
    member do
      get :stop
      get :start
      get :force_sync
    end
  end

  resources :project_logs, only: [:index, :show]
  resources :project_configs

  root to: 'landing#index'
end


