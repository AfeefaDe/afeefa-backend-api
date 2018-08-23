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

        resources :offers, controller: 'data_modules/offer/v1/offers'
        get 'offers/:id/owners', to: 'data_modules/offer/v1/offers#get_owners'
        post 'offers/:id/owners', to: 'data_modules/offer/v1/offers#link_owners'

        resources :locations, controller: 'data_plugins/location/v1/locations', only: [:index, :show]

        resources :facets, controller: 'data_plugins/facet/v1/facets', except: [:new, :edit] do
          resources :facet_items, controller: 'data_plugins/facet/v1/facet_items', except: [:new, :edit]

          post 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#link_owners'
          get 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#get_linked_owners'
          delete 'facet_items/:id/owners', to: 'data_plugins/facet/v1/facet_items#unlink_owners'
        end
        get ':owner_type/:owner_id/facet_items', to: 'data_plugins/facet/v1/facet_items#get_linked_facet_items'
        post ':owner_type/:owner_id/facet_items', to: 'data_plugins/facet/v1/facet_items#link_facet_items'

        scope :fe_navigation do
          get '', to: 'data_modules/fe_navigation/v1/fe_navigation#show'
          resources :fe_navigation_items, controller: 'data_modules/fe_navigation/v1/fe_navigation_items'

          post 'fe_navigation_items/:id/owners', to: 'data_modules/fe_navigation/v1/fe_navigation_items#link_owners'
          get 'fe_navigation_items/:id/owners', to: 'data_modules/fe_navigation/v1/fe_navigation_items#get_linked_owners'
          delete 'fe_navigation_items/:id/owners', to: 'data_modules/fe_navigation/v1/fe_navigation_items#unlink_owners'

          get 'fe_navigation_items/:id/facet_items', to: 'data_modules/fe_navigation/v1/fe_navigation_items#get_linked_facet_items'
          post 'fe_navigation_items/:id/facet_items', to: 'data_modules/fe_navigation/v1/fe_navigation_items#link_facet_items'
        end
        get ':owner_type/:owner_id/fe_navigation_items', to: 'data_modules/fe_navigation/v1/fe_navigation_items#get_linked_navigation_items'
        post ':owner_type/:owner_id/fe_navigation_items', to: 'data_modules/fe_navigation/v1/fe_navigation_items#link_navigation_items'
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

        get 'orgas/:id/projects', to: 'orgas#get_projects'
        post 'orgas/:id/projects', to: 'orgas#link_projects'

        get 'orgas/:id/project_initiators', to: 'orgas#get_project_initiators'
        post 'orgas/:id/project_initiators', to: 'orgas#link_project_initiators'

        post 'orgas/:id/networks', to: 'orgas#link_networks'
        get 'orgas/:id/networks', to: 'orgas#get_networks'

        get 'orgas/:id/network_members', to: 'orgas#get_network_members'
        post 'orgas/:id/network_members', to: 'orgas#link_network_members'

        get 'orgas/:id/partners', to: 'orgas#get_partners'
        post 'orgas/:id/partners', to: 'orgas#link_partners'

        jsonapi_resources :events
        get 'events/:id/hosts', to: 'events#get_hosts'
        post 'events/:id/hosts', to: 'events#link_hosts'

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
