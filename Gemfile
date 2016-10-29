source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use mysql2 as the database for Active Record
gem 'mysql2'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

# Use Unicorn as the app server
# platforms :ruby do
#   gem 'unicorn'
# end
# TODO: use puma for production, modify deployment!

##########################
# project relevant gems #
########################

# user authentication
gem 'devise' # see https://github.com/plataformatec/devise
# api authentication stuff
gem 'devise_token_auth' # https://github.com/lynndylanhurley/devise_token_auth

# roll and right management
# gem 'cancancan', '~> 1.10' # see https://github.com/CanCanCommunity/cancancan

# image attachments
# gem 'paperclip', '~> 4.3' # see https://github.com/thoughtbot/paperclip
# or
# gem 'carrierwave' # see https://github.com/carrierwaveuploader/carrierwave

# extract configuration to settings
gem 'config'

# json api spec
#gem 'active_model_serializers'
# if the gem above is not enough use this complex one:
gem 'jsonapi-resources'

# tree relatiions (e.g. orga-suborga)
gem 'acts_as_tree', '~> 2.4'

# state machine
gem 'aasm'

# pagination
# gem 'kaminari'

# trailblazer architecture (operations)
# gem 'trailblazer-rails'
# reform validation engine (used in reform included as contract in operations of trailblazer)
# gem 'dry-validation'

# redmine integration
# gem 'airbrake', '~> 5.4'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platform: :mri
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'

  # test framework
  gem 'minitest-rails'
  gem 'minitest-reporters'

  # for tests
  gem 'mocha'
  gem 'shoulda-context'
  gem 'capybara'
  gem 'minitest-rails-capybara'
  gem 'timecop'

  gem 'rails_best_practices'
  gem 'bullet'

  # code coverage
  gem 'simplecov', require: false

  gem 'sqlite3'
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Use Capistrano for deployment
  # gem 'capistrano-rails'
  # TODO: use puma for production, modify deployment!
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
