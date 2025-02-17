require "sidekiq/web"

Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root       "books#index"
    devise_for :users,
               path: "",
               path_names: {sign_in: "login", sign_out: "logout", sign_up: "signup"},
               controllers: {
                sessions: "users/sessions",
                registrations: "users/registrations"
               }
    get     "/cart",   to: "requests#new"
    resources :users, only: :show
    resources :authors, only: :show
    resources :books, only: %i(index show) do
      collection do
        get :search
        get :autocomplete
      end
    end
    resources :requests do
      member do
        post :handle
      end
      collection do
        get :all, to: "requests#index"
      end
    end
    resources :selected_books, only: %i(create destroy)
    resources :comments, only: %i(create destroy)
    mount Sidekiq::Web => "/sidekiq"

    namespace :api do
      namespace :v1 do
        resources :books, only: %i(index show create update destroy)
        devise_for :users, controllers: {
          sessions: "api/v1/sessions"
        }
      end
    end
  end
end
