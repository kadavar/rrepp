require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  get 'force_sync', to: 'projects#force_sync'

  resources :projects, only: [:index, :new, :create, :destroy] do
    member do
      get :stop
      get :start
    end
    collection do
      get :synchronize
    end
  end

  resources :project_logs, only: [:index, :show], param: :name
  resources :project_configs do
    collection do
      get :synchronize
    end
  end

  get 'sidekiq_web', to: 'landing#sidekiq', as: 'sidekiq'
  root to: 'landing#index'
end
