require 'test_helper'

class PhraseAppClientTest < ActiveSupport::TestCase

  setup do
    skip 'phraseapp deactivated' unless phraseapp_active?
    @client ||= PhraseAppClient.new
  end

  should 'have locales' do
    locales = @client.instance_variable_get('@locales')
    assert_equal 15, locales.size
    assert @client.instance_variable_get('@locales').key?('de')
    assert @client.instance_variable_get('@locales').key?('en')
  end

  should 'delete all keys' do
    assert orga = create(:orga)
    translations = @client.get_translation(orga, 'en')
    assert translations.any?
    @client.send(:delete_all_keys)
    translations = @client.get_translation(orga, 'en')
    assert translations.blank?
  end

  should 'handle get translation for not given key in phraseapp' do
    assert orga = build(:orga)
    assert_nil @client.send(:find_key_id_by_key_name, "orga.#{orga.id}.title")
    assert_equal({}, @client.get_translation(orga, 'en'))
    assert_nil @client.get_translation(orga, 'en')[:title]
  end

  should 'create and get translation for orga and locale' do
    assert orga = build(:orga)
    assert_not_translations(orga)

    @client.create_or_update_translation(orga, 'en')
    sleep 0.25
    assert_translations(orga)

    translation = @client.get_translation(orga, 'en')
    assert_equal Orga.translatable_attributes, translation.keys
    assert_equal 'an orga', translation[:title]
  end

  should 'update and get translation for orga and locale' do
    assert orga = create(:orga)
    assert_translations(orga)
    new_title = 'foo-bar-baz'
    assert orga.title = new_title

    @client.create_or_update_translation(orga, 'en')
    sleep 0.25
    assert_translations(orga)

    translation = @client.get_translation(orga, 'en')
    assert_equal Orga.translatable_attributes, translation.keys
    assert_not_equal 'an orga', translation[:title]
    assert_equal new_title, translation[:title]
  end

  should 'get fallback translation for orga' do
    assert orga = create(:orga)

    fallback_list = @client.instance_variable_get('@fallback_list')
    assert fallback_list.index('en') < fallback_list.index('de')

    translation = @client.get_translation(orga, 'en')
    translation_without_fallback = @client.get_translation(orga, 'en', fallback: false)
    assert_equal Orga.translatable_attributes, translation.keys
    assert_equal 'an orga', translation[:title]
    assert_equal 'this is a description of this orga', translation[:description]
    assert_equal 'this is the short description', translation[:short_description]
    assert_nil translation_without_fallback[:title]
    assert_nil translation_without_fallback[:description]
    assert_nil translation_without_fallback[:short_description]
  end

  should 'delete translation for orga and locale' do
    assert orga = create(:orga)
    sleep 0.25
    assert_translations(orga)

    @client.delete_translation(orga)
    sleep 0.25
    assert_not_translations(orga)
  end

  private

  def assert_not_translations(model)
    model.class.translatable_attributes.each do |attribute|
      key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
      key_id = @client.send(:find_key_id_by_key_name, key)
      assert_nil key_id
    end
  end

  def assert_translations(model)
    model.class.translatable_attributes.each do |attribute|
      key = "#{model.class.to_s.underscore}.#{model.id}.#{attribute}"
      key_id = @client.send(:find_key_id_by_key_name, key)
      assert key_id
    end
  end

end
