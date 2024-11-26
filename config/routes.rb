Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "home#index"
    get "/signup", to: "users#new"
    resources :users
  end
end
