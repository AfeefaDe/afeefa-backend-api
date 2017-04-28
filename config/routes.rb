Rails.application.routes.draw do
  get 'to_dos/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # routes = lambda {
  #   mount_devise_token_auth_for 'User', at: 'users'
  #
  #   resources :orgas, except: [:new, :edit] do
  #     member do
  #     end
  #   end
  #
  #   resources :users, only: [:show] do
  #     member do
  #       get :list_orgas, path: 'orgas'
  #       get :list_events, path: 'events'
  #     end
  #   end
  #
  #   resources :events, only: [:create, :show, :index]
  #
  #   get '/todos', to: 'todos#index'
  #
  # }

  scope format: false, defaults: { format: :json } do
    namespace :api do
      namespace :v1 do
        get 'facebook_events', to: 'facebook_events#index'
        get 'geocoding', to: 'geocodings#index'

        #routes.call
        mount_devise_token_auth_for 'User',
          at: 'users',
          controllers: {
            sessions: 'api/v1/sessions'
          }

        get 'meta', to: 'metas#index'
        get ':related_type/:id/events', to: 'events#get_related_resources'
        jsonapi_resources :orgas
        jsonapi_resources :events

        resources :annotation_categories, only: %i(index show)
        resources :annotations, only: %i(index show)
        resources :categories, only: %i(index show)
        resources :contact_infos, only: %i(index show)
        resources :locations, only: %i(index show)

        resources :entries, only: %i(index show)
        resources :todos, only: %i(index show)

      end
    end
  end

end
