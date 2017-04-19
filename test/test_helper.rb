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
    if phraseapp_active?
      (@client ||= PhraseAppClient.new).send(:delete_all_keys)
    end
  end

  def phraseapp_active?
    Settings.phraseapp.active rescue false
  end

  def assert_jsonable_hash(object, attributes: nil, relationships: nil)
    object_keys = %i(id type attributes)
    if (relationships.nil? || relationships.present?) && object.class.relation_whitelist_for_json.any?
      object_keys += [:relationships]
    end
    attribute_keys = object.class.attribute_whitelist_for_json
    object_hash = object.as_json(attributes: attributes, relationships: relationships)
    assert_equal(object_keys.sort, object_hash.keys.sort)
    assert_equal(attribute_keys.sort, object_hash[:attributes].keys.sort)
    if (relationships.nil? || relationships.present?) && object.class.relation_whitelist_for_json.any?
      relationships = object.class.relation_whitelist_for_json
      assert_equal(relationships.sort, object_hash[:relationships].keys.sort)
      relationships.each do |relation|
        data = object_hash[:relationships][relation]
        association = object.send(relation)
        if association.respond_to?(:map)
          assert_equal object.send(relation).map{ |x| x.to_hash(attributes: nil, relationships: nil) }, data[:data]
        else
          assert_equal object.send(relation).try(:to_hash, attributes: nil, relationships: nil), data[:data]
        end
      end
    end
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
