require 'sidekiq/web'
require 'sidetiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  resources :projects, only: [:index, :new, :destroy, :update] do
    member do
      get :stop
      get :start
      get :sync_project
    end
    collection do
      get :status
    end
  end

  resources :project_logs, only: [:index, :show], param: :name
  resources :project_configs do
    collection do
      get :synchronize
    end
  end

  get 'sidekiq_web', to: 'landing#sidekiq', as: 'sidekiq'
  get 'about',       to: 'landing#about'
  get 'contacts',    to: 'landing#contacts'

  root to: 'landing#index'
end
