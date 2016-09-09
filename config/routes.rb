Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  routes = lambda {
    mount_devise_token_auth_for 'User', at: 'users'

    resources :orgas, except: [:new, :edit] do
      member do
      end
    end
  }

  namespace :api do

    namespace :v1 do
      routes.call
    end

  end

end
