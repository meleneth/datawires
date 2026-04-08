Rails.application.routes.draw do
  resources :domains do
    resources :schemas, only: %i[index new create]
    resources :documents, only: %i[index show]
  end

  resources :schemas, only: %i[show] do
    resources :documents, only: %i[create], module: :schemas
  end

  resource :document_properties, only: [], module: :drafts do
    patch :add
    patch :remove
  end

  resources :documents, only: %i[show] do
    resource :draft, only: %i[create], module: :documents
  end

  resources :drafts, only: %i[show update destroy] do
    member do
      patch :patch_ptr
    end

    resource :schema_properties, only: [], module: :drafts do
      patch :add
      patch :remove
      patch :rename
      patch :change_type
      patch :set_required
    end

    resource :commit, only: %i[new create], module: :drafts
  end

  resources :users
  resources :rooms do
    resources :messages
  end

  root to: "domains#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
