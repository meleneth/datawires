Rails.application.routes.draw do
  resources :domains do
    resource :project_affordance, only: %i[create]
    resources :project_boards, only: %i[create]
    resource :archive, only: %i[show], controller: :domain_archives
    resources :domain_commits, only: %i[index show]
    resources :schemas, only: %i[index new create]
    resources :documents, only: %i[index show]
    resources :sources, only: %i[index new create show]
  end
  resources :domain_archives, only: %i[create]
  resources :sources, only: [] do
    resources :source_runs, only: %i[create], shallow: true
  end

  resources :schemas, only: %i[show] do
    resources :documents, only: %i[create], module: :schemas
    resources :edit_affordances, only: %i[create], module: :schemas do
      post :draft, on: :member
    end
    resources :view_affordances, only: %i[create], module: :schemas do
      post :draft, on: :member
    end
    resources :boards, only: %i[create], module: :schemas
  end

  resources :boards, only: %i[show] do
    get "actions/:id", to: "boards/actions#new", as: :action_form
    post "actions/:id", to: "boards/actions#create", as: :action
    resource :configuration, only: [], module: :boards do
      patch :update_layout
      post :add_column
      post :add_card
      delete :remove_card
    end
  end

  resources :documents, only: %i[show] do
    resource :draft, only: %i[create], module: :documents
    resources :view_affordances, only: %i[show], module: :documents
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
      patch :add_navigation
      patch :add_commit
      patch :add_screen
      patch :add_subform
      patch :add_index
      patch :add_row
      patch :apply_suggestion
      patch :update_screen
      patch :update_raw
      delete :affordance, action: :destroy_affordance
      delete "indexes/:index_index", action: :delete_index, as: :index
      get "rows/:row_index", action: :row, as: :row
      delete "rows/:row_index", action: :delete_row
      patch "rows/:row_index/move", action: :move_row, as: :move_row
      get "rows/:row_index/cells/:cell_index", action: :cell, as: :cell
      patch "rows/:row_index/cells/:cell_index", action: :update_cell
      delete "rows/:row_index/cells/:cell_index", action: :delete_cell
      patch "rows/:row_index/cells/:cell_index/move", action: :move_cell, as: :move_cell
    end
    resource :view_affordance_builder, only: %i[show], module: :drafts do
      patch :update_settings
      patch :update_raw
      delete :affordance, action: :destroy_affordance
    end
  end

  resources :users

  root to: "domains#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
