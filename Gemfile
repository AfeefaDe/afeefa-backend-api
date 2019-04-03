source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# Use mysql2 as the database for Active Record
gem 'mysql2'
# Use Unicorn as the app server
platforms :ruby do
  # keep this version of unicorn, because 5.5.0 seems not to be stable, update later
  gem 'unicorn', '~> 5.4.1'
end
# TODO: use puma for production, modify deployment!
# Use Puma as the app server
# gem 'puma', '~> 3.0'undefined method `+' for nil:NilClass

##########################
# project relevant gems #
########################

# translation
gem 'rails-i18n', '~> 5.0.0' # For 5.0.x
# user authentication
gem 'devise' # see https://github.com/plataformatec/devise
# api authentication stuff
gem 'devise_token_auth' # https://github.com/lynndylanhurley/devise_token_auth

# extract configuration to settings
gem 'config'

# json api spec
# gem 'jsonapi-resources'
gem 'jsonapi-resources', '0.9.0.beta3'

# json serialization
gem 'fast_jsonapi'

# tree relatiions (e.g. orga-suborga)
gem 'acts_as_tree'

# state machine
gem 'aasm'

# facebook api integration
# keep api stable
gem 'koala', '~> 2.2'

# strip attributes
gem 'auto_strip_attributes', '~> 2.3.0'

# geocoding
gem 'geocoder'

# geocoding nominatim (openstreetmap)
gem 'nominatim' # see https://rubygems.org/gems/nominatim/versions/0.0.6

# integrate PhraseApp
# keep api stable
gem 'phraseapp-ruby', '~> 1.3.3'

# cron
gem 'whenever'

# image
gem 'paperclip'

# http requests
gem 'http'

group :test do
  # test framework
  gem 'minitest-rails'

  # for tests
  gem 'factory_bot_rails'
  gem 'timecop'
  gem 'minitest-rails-capybara'
  gem 'minitest', '5.10.2'
  gem 'mocha'
  gem 'shoulda-context'

  # code coverage
  gem 'ruby-prof'
  gem 'simplecov', require: false

  # request recording for tests
  gem 'vcr'
  # mock requests in tests, needed by vcr
  gem 'webmock'

  # We do not longer use sqlite3:
  # gem 'sqlite3'
end

group :test, :development do
  gem 'rails_best_practices'
  gem 'bullet'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platform: :mri
  # comfortable rails console and debugger, also useful in production:
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :development do
  # documentation
  gem 'railroady'
  gem 'rails-erd'

  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

  # Use Capistrano for deployment
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
