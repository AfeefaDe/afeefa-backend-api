require 'test_helper'

class PhraseAppClientTest < ActiveSupport::TestCase

  setup do
    @client ||= PhraseAppClient.new
  end

  should 'have locales' do
    skip 'foobar'

    locales = @client.instance_variable_get('@locales')
    assert_equal 15, locales.size
    assert @client.instance_variable_get('@locales').key?('de')
    assert @client.instance_variable_get('@locales').key?('en')
  end

  should 'handle get translation for not given key in phraseapp' do
    skip 'foobar'

    assert orga = build(:orga)
    assert_nil @client.send(:find_key_id_by_key_name, "orga.#{orga.id}.title")
    assert_equal({}, @client.get_translation(orga, 'en'))
    assert_nil @client.get_translation(orga, 'en')[:title]
  end

  should 'create and get translation for orga and locale' do
    skip 'foobar'

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
    skip 'foobar'

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
    skip 'foobar'

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

  should 'delete all keys' do
    skip 'foobar'

    assert orga = create(:orga)
    translations = @client.get_translation(orga, 'en')
    assert translations.any?
    @client.send(:delete_all_keys)
    translations = @client.get_translation(orga, 'en')
    assert translations.blank?
  end

  should 'delete all unsused keys' do
    existing_orga = create(:orga)

    orga_whithout_title = build(:orga)
    orga_whithout_title.title = ''
    orga_whithout_title.skip_all_validations!
    orga_whithout_title.save

    orga_whithout_short_description = build(:orga)
    orga_whithout_short_description.short_description = ''
    orga_whithout_short_description.skip_all_validations!
    orga_whithout_short_description.save

    orga_whithout_attributes = build(:orga)
    orga_whithout_attributes.title = ''
    orga_whithout_attributes.short_description = ''
    orga_whithout_attributes.skip_all_validations!
    orga_whithout_attributes.save

    json = parse_json_file file: 'phraseapp_locale_de.json' do |payload|
      payload.gsub!('<existing_orga_id>', existing_orga.id.to_s)
      payload.gsub!('<nonexisting_orga_id>', 100000000000000.to_s)
      payload.gsub!('<orga_whithout_title_id>', orga_whithout_title.id.to_s)
      payload.gsub!('<orga_whithout_short_description_id>', orga_whithout_short_description.id.to_s)
      payload.gsub!('<orga_whithout_attributes_id>', orga_whithout_attributes.id.to_s)
    end

    PhraseAppClient.any_instance.expects(:download_locale).returns(json)

    expect_deletes_key("orga.100000000000000.*")
    expect_deletes_key("orga.#{orga_whithout_title.id}.title")
    expect_deletes_key("orga.#{orga_whithout_short_description.id}.short_description")
    expect_deletes_key("orga.#{orga_whithout_attributes.id}.title")
    expect_deletes_key("orga.#{orga_whithout_attributes.id}.short_description")

    @client.delete_unused_keys(dry_run: false)

    assert true
  end

  def expect_deletes_key(key)
    params = create_delete_params(key)
    result = mock()
    result.stubs(:records_affected).returns(1)
    PhraseApp::Client.any_instance.expects(:keys_delete)
      .once
      .with(Settings.phraseapp.test_project_id, params)
      .returns([result])
  end

  def create_delete_params(key)
    PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
  end

  should 'delete translation for orga and locale' do
    skip 'foobar'
    assert orga = create(:orga)
    sleep 0.25
    assert_translations(orga)

    @client.delete_translation(orga, dry_run: false)
    sleep 0.25
    assert_not_translations(orga)
  end

  should 'download locale file' do
    VCR.use_cassette('download_locale_en') do
      json = @client.send(:download_locale, 'en')
      assert_equal ['event', 'orga'], json.keys
    end
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
