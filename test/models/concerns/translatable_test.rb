require 'test_helper'

class TranslatableTest < ActiveSupport::TestCase

  should 'not update phraseapp translation if force flag is not set' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:push_locale_file).never

    orga.update_or_create_translations
  end

  should 'always update phraseapp translation if force flag is set' do
    orga = create(:orga)
    orga_id = orga.id.to_s
    orga.force_translatable_attribute_update!
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'an orga', json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
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

      hash = orga.send(:build_json_for_phraseapp)

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

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'an orga', json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.save
  end

  should 'not create translation on entry create if related attributes are empty' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.title = ''
    orga.short_description = ''
    orga.skip_all_validations!

    PhraseAppClient.any_instance.expects(:push_locale_file).never

    assert orga.save
  end

  should 'only create translation for nonempty attributes on entry create' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.title = ''
    orga.skip_all_validations!

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_nil json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.save
  end

  should 'update translation on entry update' do
    orga = create(:orga)
    orga_id = orga.id.to_s
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'foo-bar', json['orga'][orga_id]['title']
      assert_equal 'short-fo-ba', json['orga'][orga_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'update translation on entry update only once' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:push_locale_file).once.with do |file, phraseapp_locale_id, tags_hash|
      assert true
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'not update translation on entry update if all related attributes are empty' do
    orga = create(:orga)
    orga.force_translation_after_save = true
    orga.skip_all_validations!

    PhraseAppClient.any_instance.expects(:push_locale_file).never

    assert orga.update(title: '', short_description: '')
  end

  should 'only update translation for nonempty attributes on entry update' do
    orga = create(:orga)
    orga.force_translation_after_save = true
    orga.skip_all_validations!

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_nil json['orga'][orga_id]['title']
      assert_equal 'short-fo-ba', json['orga'][orga_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.update(title: '', short_description: 'short-fo-ba')
  end


  should 'remove translations of all attributes on entry delete' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:delete_translation).with do |orga_to_delete, dry_run_hash|
      assert_equal orga, orga_to_delete
      assert !dry_run_hash[:dry_run]
    end

    assert orga.destroy
  end
end
