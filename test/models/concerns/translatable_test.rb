require 'test_helper'

class TranslatableTest < ActiveSupport::TestCase

  should 'not update phraseapp translation if force flag is not set' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    orga.update_or_create_translations
  end

  should 'always update phraseapp translation if force flag is set' do
    orga = create(:orga)
    orga_id = orga.id.to_s
    orga.force_translatable_attribute_update!
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'an orga', json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    orga.update_or_create_translations
  end


  should 'build json for phraseapp' do
    VCR.use_cassette('generate_json_for_phraseapp') do
      orga = create(:orga)
      Orga::translatable_attributes.each do |attribute|
        orga.send("#{attribute}=", "#{Time.current.to_s} change xyz")
      end

      hash = orga.send(:create_json_for_translation_file)

      assert_equal ['orga'], hash.keys

      rendered_orgas = hash.values
      assert_equal 1, rendered_orgas.count

      rendered_orga = rendered_orgas.first
      assert_equal 1, rendered_orga.keys.count
      assert_equal orga.id.to_s, rendered_orga.keys.first

      attributes = rendered_orga.values.first
      assert_equal Orga::translatable_attributes.map(&:to_s), attributes.keys
      attributes.each do |attribute, value|
        assert_equal orga.send(attribute), value
      end
    end
  end

  should 'create translation on entry create' do
    orga = build(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'an orga', json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.save
  end

  should 'not create translation on entry create if related attributes are empty' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.title = ''
    orga.short_description = ''

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    assert orga.save(validate: false)
  end

  should 'only create translation for nonempty attributes on entry create' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.title = ''

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_nil json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.save(validate: false)
  end

  should 'set area tag on create translation' do
    orga = build(:orga)
    orga.area = 'heinz_landkreis'
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      assert_equal 'heinz_landkreis', tags_hash[:tags]
    end

    assert orga.save
  end

  should 'update translation on entry update' do
    orga = create(:orga)
    orga_id = orga.id.to_s
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'foo-bar', json['orga'][orga_id]['title']
      assert_equal 'short-fo-ba', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'set area tag on update translation' do
    orga = create(:orga)
    orga.area = 'heinz_landkreis'
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      assert_equal 'heinz_landkreis', tags_hash[:tags]
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'update translation on entry update only once' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).once.with do |file, phraseapp_locale_id, tags_hash|
      assert true
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'not update translation on entry update if all related attributes are empty' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    orga.assign_attributes(title: '', short_description: '')
    assert orga.save(validate: false)
  end

  should 'only update translation for nonempty attributes on entry update' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_nil json['orga'][orga_id]['title']
      assert_equal 'short-fo-ba', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    orga.assign_attributes(title: '', short_description: 'short-fo-ba')
    assert orga.save(validate: false)
  end


  should 'remove translations of all attributes on entry delete' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:delete_translation).with do |orga_to_delete|
      assert_equal orga, orga_to_delete
    end

    assert orga.destroy
  end
end
