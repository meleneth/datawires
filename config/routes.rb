Rails.application.routes.draw do
  resources :domains do
    resources :schemas, only: %i[index new create]
    resources :documents, only: %i[index show]
  end

  resources :schemas, only: %i[show] do
    resources :documents, only: %i[create], module: :schemas
    resources :edit_affordances, only: %i[create], module: :schemas
  end

  resources :documents, only: %i[show] do
    resource :draft, only: %i[create], module: :documents
  end

  resources :drafts, only: %i[show destroy] do
    member do
      patch :patch_ptr
      patch :add_item
      patch :remove_item
      patch :reorder_item
    end

    resource :schema_properties, only: [], module: :drafts do
      patch :add
      patch :remove
      patch :rename
      patch :change_type
      patch :set_required
    end

    resource :commit, only: %i[new create], module: :drafts
    resource :edit_affordance_builder, only: %i[show], module: :drafts do
      patch :add_field
      patch :add_row
      patch :update_screen
      patch :update_raw
      get "rows/:row_index", action: :row, as: :row
      delete "rows/:row_index", action: :delete_row
      get "rows/:row_index/cells/:cell_index", action: :cell, as: :cell
      delete "rows/:row_index/cells/:cell_index", action: :delete_cell
      patch "rows/:row_index/cells/:cell_index/move", action: :move_cell, as: :move_cell
    end
  end

  resources :users

  root to: "domains#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
