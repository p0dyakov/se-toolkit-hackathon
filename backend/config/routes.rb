Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/api-docs", to: "api_docs#show"
  get "/openapi/v1/openapi.json", to: "openapi#show"
  mount Rswag::Api::Engine => "/openapi" if defined?(Rswag::Api::Engine)

  match "/auth/google_oauth2/callback", to: "oauth_callbacks#google", via: %i[get post]
  get "/auth/failure", to: "oauth_callbacks#failure"

  namespace :api do
    namespace :v1 do
      resource :me, only: %i[show destroy], controller: :profiles
      post "me/api-key", to: "profiles#rotate_api_key"
      resource :session, only: :destroy, controller: :sessions
      resources :conversions, only: %i[index create show update destroy] do
        member do
          get :download
          get :download_source
        end
      end
    end
  end

  if Rails.env.test?
    namespace :test do
      post "sign_in/:user_id", to: "sessions#create"
    end
  end
end
