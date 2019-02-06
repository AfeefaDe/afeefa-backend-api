require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Decorators', 'app/decorators'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'mocha/mini_test'

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
require 'minitest/rails/capybara'

require 'pp'

# VCR integration and mocks for APIs
require 'vcr'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'test/data/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb

  config.default_cassette_options = {
    record: :once,
    erb: true
  }
end

require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: false)

# TODO: This is needed because of the strange issues in frontend api... DAMN!
require File.expand_path('../../db/seeds', __FILE__)
::Seeds.recreate_all


def parse_json_file(file: 'create_orga_with_nested_models.json')
  content = File.read(Rails.root.join('test', 'data', 'json', file))
  yield content if block_given?
  JSON.parse(content)
end

# include shared test modules
# by convention stored in 'concerns' and named
# starting with 'acts_as'
Dir[Rails.root.join("test/**/*.rb")].each do |f|
  file_name = File.absolute_path f
  if file_name.include?('concerns/acts_as')
    require f
  end
end

class ActiveSupport::TestCase

  setup do
    @valid_user = valid_user
    Current.stubs(:user).returns(@valid_user)
  end

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  include FactoryBot::Syntax::Methods

  def valid_user
    User.create!(
      email: "foo#{rand(0..10000000)}@afeefa.de",
      forename: 'Max',
      surname: 'Mustermann',
      # TODO: remove required password from device
      password: 'abc12346',
      area: 'dresden'
    )
  end

  def facebook_active?
    Settings.facebook.active rescue false
  end

  def assert_equal_with_nil(val1, val2)
    if val1.nil?
      assert_nil val2
    else
      assert_equal val1, val2
    end
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

        if object.respond_to?("#{relation}_to_hash")
          if data[:data].nil?
            assert_nil object.try("#{relation}_to_hash")
          else
            assert_equal object.try("#{relation}_to_hash"), data[:data]
          end
        else
          if association.respond_to?(:map)
            assert_equal object.send(relation).map{ |x| x.to_hash(attributes: nil, relationships: nil) }, data[:data]
          else
            if data[:data].nil?
              assert_nil object.send(relation).try(:to_hash, attributes: nil, relationships: nil)
            else
              assert_equal object.send(relation).try(:to_hash, attributes: nil, relationships: nil), data[:data]
            end
          end
        end

      end
    end
  end

  def assert_fapi_cache_job(
    job: nil,
    entry: nil,
    entry_id: nil,
    entry_type: nil,
    areaTitle: nil,
    updated: false,
    deleted: false,
    translated: false,
    language: nil
    )

    if entry_id # in case of removal we cannot fetch the entry association any longer
      assert_equal entry_id, job.entry_id
      assert_equal entry_type, job.entry_type
    else
      assert_equal_with_nil entry, job.entry
    end
    assert_equal_with_nil areaTitle, (job.area ? job.area.title : nil)
    assert_equal updated, job.updated || false # updated is nil by default
    assert_equal deleted, job.deleted || false # deleted is nil by default
    assert_equal translated, job.translated || false # translated is nil by default
    assert_equal_with_nil language, job.language
    assert_equal Time.current.beginning_of_minute.as_json, job.created_at.beginning_of_minute.as_json
    assert_nil job.started_at
    assert_nil job.finished_at
  end

  def assert_same_elements(expected, given)
    assert (expected - given).blank?, 'The given array misses some expected elements.'
    assert (given - expected).blank?, 'The given array contains unexpected elements.'
  end

end

class ActionController::TestCase

  setup do
    request.class.any_instance.stubs(:content_type).returns(JSONAPI::MEDIA_TYPE)
  end

  private

  def stub_current_user(user: @valid_user)
    @controller.class.any_instance.stubs(:set_user_by_token).returns(user)
  end

  def unstub_current_user
    @controller.class.any_instance.unstub(:set_user_by_token)
  end

end
