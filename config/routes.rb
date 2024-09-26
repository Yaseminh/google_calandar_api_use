Rails.application.routes.draw do
  root 'calendar_events#index'

  get 'auth/connect', to: 'google_auth#connect', as: :google_connect
  get 'auth/callback', to: 'google_auth#callback', as: :google_callback
  get 'sign_in', to: 'sessions#new', as: :sign_in
  delete 'sign_out', to: 'sessions#destroy', as: :destroy_session
  get 'calendar_events', to: 'calendar_events#index', as: :calendar_events
  resources :calendar_events do
    # Nested resources are usually not needed here for events
    # If you intend to use nested events, you can keep this part; otherwise, remove it.
    # resources :events, only: [:new, :create, :edit, :update, :destroy]
  end
  resources :calendar_events


  # `events` path can be created directly or as part of `calendar_events`
  # This might be redundant since you already have the resources defined.
  # Remove this line if you want to use the resources directly.
  # get 'calendar_events', to: 'calendar_events#index', as: :calendar_events

  # Since `resources :calendar_events` already provides a path to index, you don't need to redefine it
  # get 'calendar_events', to: 'calendar_events#index', as: :events

  # If you want a separate path for new events
  get 'calendar_events/new', to: 'calendar_events#new', as: :new_events

end
