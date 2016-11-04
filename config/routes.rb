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
        #routes.call
        mount_devise_token_auth_for 'User',
          at: 'users',
          controllers: {
            sessions: 'api/v1/sessions'
          }

        jsonapi_resources :orgas
        jsonapi_resources :users
        jsonapi_resources :events
        jsonapi_resources :entries
        jsonapi_resources :annotations
        jsonapi_resources :contact_infos
        jsonapi_resources :locations

      end
    end
  end

end
