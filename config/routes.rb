Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth
      post "users/signup", to: "users#signup"
      post "auth/signin",  to: "auth#signin"

      # Contents (with alias /content → /contents#index)
      resources :contents, only: %i[index show create update destroy]
      get "content", to: "contents#index"
    end
  end

  # Health check
  get "/up", to: proc { [200, {}, ["OK"]] }
end
