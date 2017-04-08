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
# TODO: VCR integration and mocks for APIs
# require 'vcr'
#
# VCR.configure do |config|
#   config.cassette_library_dir = "fixtures/vcr_cassettes"
#   config.hook_into :webmock # or :fakeweb
# end

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  include FactoryGirl::Syntax::Methods

  def valid_user
    User.create!(
      email: "foo#{rand(0..1000)}@afeefa.de",
      forename: 'Max',
      surname: 'Mustermann',
      # TODO: remove required password from device
      password: 'abc12346'
    )
  end

  teardown do
    PhraseAppClient.new.send(:delete_all_keys)
  end

end

class ActionController::TestCase

  setup do
    request.class.any_instance.stubs(:content_type).returns(JSONAPI::MEDIA_TYPE)
    # stub phraseapp stuff
    Orga.any_instance.stubs(:update_or_create_translations).returns(true)
    Event.any_instance.stubs(:update_or_create_translations).returns(true)
  end

  private

  def stub_current_user(user: valid_user)
    @controller.class.any_instance.stubs(:set_user_by_token).returns(user)
  end

  def unstub_current_user
    @controller.class.any_instance.unstub(:set_user_by_token)
  end

  def parse_json_file(file: 'create_orga_with_nested_models.json')
    content = File.read(Rails.root.join('test', 'data', file))
    yield content if block_given?
    JSON.parse(content)
  end

end
