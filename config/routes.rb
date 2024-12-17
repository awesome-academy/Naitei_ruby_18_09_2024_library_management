Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root    "books#index"
    get     "/signup", to: "users#new"
    get     "/login",  to: "sessions#new"
    post    "/login",  to: "sessions#create"
    delete  "/logout", to: "sessions#destroy"
    get     "/cart",   to: "requests#new"
    resources :users
    resources :books do
      collection do
        get :search, to: "books#search"
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
  end
end
