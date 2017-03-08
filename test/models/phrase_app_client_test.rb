require 'test_helper'
require 'phrase_app_client'

class PhraseAppClientTest < ActiveSupport::TestCase

  setup do
    @client = PhraseAppClient.new
  end

  should 'have locales' do
    locales = @client.instance_variable_get('@locales')
    assert_equal 2, locales.size
    assert @client.instance_variable_get('@locales').key?('de')
    assert @client.instance_variable_get('@locales').key?('en')
  end

  should 'handle get translation for not given key in phraseapp' do
    assert orga = create(:orga)
    assert_nil @client.find_key_id_by_key_name("orga.#{orga.id}.title")
    assert_equal({}, @client.get_translation(orga, 'en'))
    assert_nil @client.get_translation(orga, 'en')[:title]
  end

  should 'create and get translation for orga and locale' do
    assert orga = create(:orga)

    assert_not_translations(orga)
    @client.create_translation(orga, 'en')
    sleep 0.25
    assert_translations(orga)

    translation = @client.get_translation(orga, 'en')
    assert_equal Orga.translatable_attributes, translation.keys
    assert_equal 'an orga', translation[:title]
  end

  should 'get fallback translation for orga' do
    assert orga = create(:orga)
    @client.create_translation(orga, 'de')

    fallback_list = @client.instance_variable_get('@fallback_list')
    assert fallback_list.index('en') < fallback_list.index('de')

    translation = @client.get_translation(orga, 'en')
    translation_without_fallback = @client.get_translation(orga, 'en', fallback: false)
    assert_equal Orga.translatable_attributes, translation.keys
    assert_equal 'an orga', translation[:title]
    assert_equal 'this is a short description of this orga', translation[:description]
    assert_nil translation_without_fallback[:title]
    assert_nil translation_without_fallback[:description]
  end

  should 'delete translation for orga and locale' do
    assert orga = create(:orga)
    @client.create_translation(orga, 'en')
    sleep 0.25
    assert_translations(orga)

    @client.delete_translation(orga)
    sleep 0.25
    assert_not_translations(orga)
  end

  private

  def assert_not_translations(model)
    model.class.translatable_attributes.each do |attribute|
      assert_nil @client.find_key_id_by_key_name("#{model.class.to_s.underscore}.#{model.id}.#{attribute}")
    end
  end

  def assert_translations(model)
    model.class.translatable_attributes.each do |attribute|
      assert @client.find_key_id_by_key_name("#{model.class.to_s.underscore}.#{model.id}.#{attribute}")
    end
  end

end
