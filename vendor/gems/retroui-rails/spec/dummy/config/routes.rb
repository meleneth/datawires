# frozen_string_literal: true

Dummy::Application.routes.draw do
  root "demo#index"
  get "components", to: "demo#index"
end
