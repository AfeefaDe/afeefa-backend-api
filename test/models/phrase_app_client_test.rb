require 'test_helper'

class PhraseAppClientTest < ActiveSupport::TestCase

  setup do
    @client ||= PhraseAppClient.new
  end

  should 'delete all keys' do
    expect_deletes_key("*")

    num_deletes = @client.send(:delete_all_keys)

    assert_equal 1, num_deletes
  end

  should 'delete given keys by name' do
    orga = build(:orga)
    orga.skip_all_validations!
    orga.force_translation_after_save = true
    orga.save

    orga2 = build(:orga)
    orga2.skip_all_validations!
    orga2.force_translation_after_save = true
    orga2.save

    orga3 = build(:orga)
    orga3.skip_all_validations!
    orga3.force_translation_after_save = true
    orga3.save

    orga4 = build(:orga)
    orga4.skip_all_validations!
    orga4.force_translation_after_save = true
    orga4.save

    orga5 = build(:orga)
    orga5.skip_all_validations!
    orga5.force_translation_after_save = true
    orga5.save

    keys_do_delete = [
      "orga.#{orga.id}.title",
      "orga.#{orga2.id}.title",
      "orga.#{orga2.id}.short_description",
      "orga.#{orga3.id}.title",
      "orga.#{orga3.id}.short_description",
      "orga.#{orga4.id}.short_description",
      "orga.#{orga5.id}.short_description"
    ]

    num_deletes = @client.delete_keys_by_name(keys_do_delete)

    assert_equal 7, num_deletes
  end

  should 'tag given models' do
    orga = build(:orga)
    orga.skip_all_validations!
    orga.force_translation_after_save = true
    orga.save

    orga2 = build(:orga)
    orga2.title = '' # won't get tagged
    orga2.skip_all_validations!
    orga2.force_translation_after_save = true
    orga2.save

    orga3 = build(:orga)
    orga3.skip_all_validations!
    orga3.force_translation_after_save = true
    orga3.save

    orga4 = build(:orga)
    orga4.short_description = '' # won't get tagged
    orga4.skip_all_validations!
    orga4.force_translation_after_save = true
    orga4.save

    orga5 = build(:orga)
    orga5.skip_all_validations!
    orga5.force_translation_after_save = true
    orga5.save

    num_tagged = @client.tag_models('hana_war_hier', [orga, orga2, orga3, orga4, orga5])

    assert_equal 8, num_tagged
  end

  should 'delete translations of the given model' do
    orga = create(:orga)

    expect_deletes_key("orga.#{orga.id}.title")
    expect_deletes_key("orga.#{orga.id}.short_description")

    num_deletes = @client.delete_translation(orga)

    assert_equal 2, num_deletes
  end

  should 'delete all unused keys' do
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

    expected_keys = [
      "orga.100000000000000.title",
      "orga.100000000000000.short_description",
      "orga.#{orga_whithout_title.id}.title",
      "orga.#{orga_whithout_short_description.id}.short_description",
      "orga.#{orga_whithout_attributes.id}.title",
      "orga.#{orga_whithout_attributes.id}.short_description"
    ]

    result = mock()
    result.stubs(:records_affected).returns(6)
    PhraseApp::Client.any_instance.expects(:keys_delete)
      .once
      .with do |project_id, params|
        q = 'name:' + expected_keys.join(',')
        assert_equal q, params.q
      end
      .returns([result])

    num_deletes = @client.delete_unused_keys(json)

    assert_equal 6, num_deletes
  end

  should 'add missing keys' do
    existing_orga = create(:orga)

    orga_whithout_title = build(:orga)
    orga_whithout_title.title = 'orga_whithout_title'
    orga_whithout_title.skip_all_validations!
    orga_whithout_title.save

    orga_whithout_short_description = build(:orga)
    orga_whithout_short_description.title = 'orga_whithout_short_description'
    orga_whithout_short_description.skip_all_validations!
    orga_whithout_short_description.save

    new_orga = build(:orga)
    new_orga.title = 'new_orga'
    new_orga.skip_all_validations!
    new_orga.save

    json = parse_json_file file: 'phraseapp_locale_de_unsynced.json' do |payload|
      payload.gsub!('<existing_orga_id>', existing_orga.id.to_s)
      payload.gsub!('<orga_whithout_title_id>', orga_whithout_title.id.to_s)
      payload.gsub!('<orga_whithout_short_description_id>', orga_whithout_short_description.id.to_s)
    end

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_equal 4, json['orga'].length
    end

    num_added = @client.add_missing_or_invalid_keys(json)

    assert_equal 4, num_added
  end

  should 'download locale file' do
    VCR.use_cassette('download_locale_en') do
      json = @client.send(:download_locale, 'en')
      assert_equal ['event', 'orga'], json.keys
    end
  end

  private

  def expect_deletes_key(key)
    params = PhraseApp::RequestParams::KeysDeleteParams.new(q: key)
    result = mock()
    result.stubs(:records_affected).returns(1)
    PhraseApp::Client.any_instance.expects(:keys_delete)
      .once
      .with(Settings.phraseapp.test_project_id, params)
      .returns([result])
  end

end
