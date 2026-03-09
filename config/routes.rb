Rails.application.routes.draw do
  resources :domains do
    resources :schemas, only: %i[index new create]
    resources :documents, param: :key, only: %i[index show]
  end

  resources :schemas, only: %i[show]

  resources :documents, only: [] do
    resource :draft, only: %i[create]
  end

  resources :drafts, only: %i[show update destroy] do
    member do
      patch :patch_ptr
    end

    resource :commit, only: %i[new create], module: :drafts
  end

  resources :users
  resources :rooms do
    resources :messages
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
