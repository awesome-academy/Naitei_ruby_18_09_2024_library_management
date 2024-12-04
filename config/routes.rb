Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root    "books#index"
    get     "/signup", to: "users#new"
    get     "/login",  to: "sessions#new"
    post    "/login",  to: "sessions#create"
    delete  "/logout", to: "sessions#destroy"
    get     "/cart",   to: "requests#new"
    resources :users
    resources :books
    resources :requests
  end
end
