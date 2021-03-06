require 'sidekiq/web'

Rails.application.routes.draw do
  resources :jira_accounts,only: [:index, :create, :destroy, :update, :edit]

  resources :pivotal_accounts,only: [:index, :create, :destroy, :update, :edit]

  mount Sidekiq::Web => '/sidekiq'

  resources :projects, only: [:index, :new, :create, :destroy, :edit, :update] do
    member do
      get :stop
      get :start
      get :sync_project
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
  get 'about',       to: 'landing#about'
  get 'contacts',    to: 'landing#contacts'

  root to: 'landing#index'
end
