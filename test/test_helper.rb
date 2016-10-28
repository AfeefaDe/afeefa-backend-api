require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Decorators', 'app/decorators'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'mocha/mini_test'
require 'minitest/reporters'
Minitest::Reporters.use!

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
require 'minitest/rails/capybara'

# Uncomment for awesome colorful output
# require "minitest/pride"

require 'pp'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  # TODO: uncomment this if you want to use factory girl
  # include FactoryGirl::Syntax::Methods

  def admin
    Role.where(title: Role::ORGA_ADMIN).first.user
  end

  def member
    Role.where(title: Role::ORGA_MEMBER).first.user
  end

  def valid_user
    User.create(
      email: "foo#{rand(0..1000)}@afeefa.de",
      forename: 'Max',
      surname: 'Mustermann',
      # TODO: remove required password from device
      password: 'abc12346'
    )
  end

  def event
    Event.create(
      title: 'TestEvent',
      description: 'Description of TestEvent'
    )
  end
end

class ActionController::TestCase

  setup do
    request.class.any_instance.stubs(:content_type).returns(JSONAPI::MEDIA_TYPE)
  end

  private

  def stub_current_user(user:)
    @controller.class.any_instance.stubs(:set_user_by_token).returns(user)
  end

  def unstub_current_user
    @controller.class.any_instance.unstub(:set_user_by_token)
  end

end
