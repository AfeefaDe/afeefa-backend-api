Rails.application.routes.draw do
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

  scope format: false, defaults: {format: :json} do
    scope :api do
      scope :v1 do
        get ':owner_type/:owner_id/contacts', to: 'data_plugins/contact/v1/contacts#index'
        post ':owner_type/:owner_id/contacts', to: 'data_plugins/contact/v1/contacts#create'
        patch ':owner_type/:owner_id/contacts/:id', to: 'data_plugins/contact/v1/contacts#update'
        delete ':owner_type/:owner_id/contacts/:id', to: 'data_plugins/contact/v1/contacts#delete'

        resources :locations, controller: 'data_plugins/location/v1/locations', only: [:index, :show]
        resources :facets, controller: 'data_plugins/facet/v1/facets', except: [:new, :edit] do
          resources :facet_items, controller: 'data_plugins/facet/v1/facet_items', except: [:new, :edit]
          get 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#get_linked_owners'
          post 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#link_owners'
          post 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#unlink_owners'
        end

        get ':owner_type/:owner_id/facet_items', to: 'data_plugins/facet/v1/owner_facet_items#get_linked_facet_items'
        post ':owner_type/:owner_id/facet_items/:facet_item_id', to: 'data_plugins/facet/v1/owner_facet_items#link_facet_item'
        delete ':owner_type/:owner_id/facet_items/:facet_item_id', to: 'data_plugins/facet/v1/owner_facet_items#unlink_facet_item'
      end
    end

    namespace :api do
      namespace :v1 do
        # TODO: Should we move them to frontend api?
        get 'facebook_events', to: 'facebook_events#index'
        get 'geocoding', to: 'geocodings#index'

        get 'translations', to: 'translation_cache#index'
        post 'translations', to: 'translation_cache#update'
        post 'translations/phraseapp_webhook', to: 'translation_cache#phraseapp_webhook'

        #routes.call, generates /sign_in and /sign_out and probably more ;-)
        mount_devise_token_auth_for 'User',
          at: 'users',
          controllers: {
            sessions: 'api/v1/sessions',
            token_validations: 'api/v1/token_validations'
          }

        get 'meta', to: 'metas#index'
        get ':related_type/:id/events', to: 'events#get_related_resources'
        get ':owner_type/:owner_id/annotations', to: 'annotations#get_owner_annotations'
        get ':owner_type/:owner_id/resource_items', to: 'resource_items#get_owner_resources'

        jsonapi_resources :orgas

        get 'orgas/:id/actor_relations', to: 'orgas#get_actor_relations'
        post 'orgas/:id/projects/:item_id', to: 'orgas#add_project'
        delete 'orgas/:id/projects/:item_id', to: 'orgas#remove_project'

        post 'orgas/:id/network_members/:item_id', to: 'orgas#add_network_member'
        delete 'orgas/:id/network_members/:item_id', to: 'orgas#remove_network_member'

        post 'orgas/:id/partners/:item_id', to: 'orgas#add_partner'
        delete 'orgas/:id/partners/:item_id', to: 'orgas#remove_partner'

        jsonapi_resources :events

        resources :annotation_categories, only: %i(index show)
        resources :annotations, only: %i(index show)
        resources :resource_items, only: %i(index show)
        resources :categories, only: %i(index show)
        resources :contact_infos, only: %i(index show)

        resources :entries, only: %i(index show)
        resources :todos, only: %i(index show)
        resources :users, only: %i(update)

        resources :chapters
      end
    end
  end
end
