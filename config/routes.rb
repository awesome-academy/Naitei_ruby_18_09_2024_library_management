Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "home#index"
    get  "/signup", to: "users#new"
    get  "/login",  to: "sessions#new"
    post "/login",  to: "sessions#create"
    get  "/logout", to: "sessions#destroy"
    resources :users
  end
end
