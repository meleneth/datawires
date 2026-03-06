Rails.application.routes.draw do
  resources :domains do
    resources :schemas, only: %i[index new create show]

    resources :documents, param: :key, only: %i[index show] do
      resources :drafts, only: %i[show] do
        resource :commit, only: %i[new create], module: :drafts

        member do
          patch :patch_ptr
        end
      end
    end
  end

  resources :users
  resources :rooms do
    resources :messages
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
