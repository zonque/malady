Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  constraints(->(_) { Malady.signups_allowed? }) do
    devise_scope :user do
      resource :registration,
               only: [ :new, :create ],
               controller: "devise/registrations",
               as: :user_registration,
               path: "users"
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    resources :users, only: [ :index, :show, :destroy ] do
      member do
        post :lock
        post :unlock
        post :confirm
      end
    end
  end

  namespace :metrics do
    resource :positions, only: [ :update ]
  end

  resources :metrics do
    resources :data_points, only: [ :create, :edit, :update, :destroy ]
    resource :metric_type, only: [ :edit, :update ]
  end

  namespace :api do
    namespace :v1 do
      resources :metrics, only: [ :index, :show ], param: :slug do
        get :series, on: :member
      end
    end
  end

  # The overview now lives at the metrics index (metrics#index). Keep /overview
  # working for old links by redirecting it there.
  get "overview", to: redirect("/metrics")
  resource :timezone, only: [ :update ]

  resource :quick_entry, only: [ :new, :create ]

  resource :api_token, only: [ :show, :update ]

  resource :export, only: [], controller: "exports" do
    get :json
    get :csv
  end

  root "dashboard#show"

  # Defines the root path route ("/")
  # root "posts#index"
end
