require 'test_helper'

class PhraseAppClientTest < ActiveSupport::TestCase

  setup do
    @client ||= PhraseAppClient.new
    # WebMock.allow_net_connect!(allow_localhost: false)
  end

  teardown do
    # WebMock.disable_net_connect!(allow_localhost: false)
  end

  should 'delete all keys' do
    expect_deletes_key("*")

    num_deletes = @client.send(:delete_all_keys)

    assert_equal 1, num_deletes
  end

  should 'delete given keys by name' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.save(validate: false)

    orga2 = build(:orga)
    orga2.force_translation_after_save = true
    orga2.save(validate: false)

    orga3 = build(:orga)
    orga3.force_translation_after_save = true
    orga3.save(validate: false)

    orga4 = build(:orga)
    orga4.force_translation_after_save = true
    orga4.save(validate: false)

    orga5 = build(:orga)
    orga5.force_translation_after_save = true
    orga5.save(validate: false)

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
    orga.force_translation_after_save = true
    orga.save(validate: false)

    orga2 = build(:orga)
    orga2.title = '' # won't get tagged
    orga2.force_translation_after_save = true
    orga2.save(validate: false)

    orga3 = build(:orga)
    orga3.force_translation_after_save = true
    orga3.save(validate: false)

    orga4 = build(:orga)
    orga4.short_description = '' # won't get tagged
    orga4.force_translation_after_save = true
    orga4.save(validate: false)

    orga5 = build(:orga)
    orga5.force_translation_after_save = true
    orga5.save(validate: false)

    @client.delete_tag('hana_war_hier')

    num_tagged = @client.tag_models('hana_war_hier', [orga, orga2, orga3, orga4, orga5])

    assert_equal 8, num_tagged

    assert_equal 8, @client.get_count_keys_for_tag('hana_war_hier')
  end

  should 'delete tag' do
    orga = build(:orga)
    orga.area = 'leipzig'
    orga.force_translation_after_save = true
    orga.save(validate: false)

    orga2 = build(:orga)
    orga2.area = 'leipzig'
    orga2.force_translation_after_save = true
    orga2.save(validate: false)

    assert @client.get_count_keys_for_tag('leipzig') > 0

    @client.delete_tag('leipzig')

    assert_equal 0, @client.get_count_keys_for_tag('leipzig')

    # handle key not found

    @client.delete_tag('leipzig')
  end

  should 'delete all area tags' do
    PhraseAppClient.any_instance.expects(:delete_tag).with('leipzig')
    PhraseAppClient.any_instance.expects(:delete_tag).with('bautzen')
    PhraseAppClient.any_instance.expects(:delete_tag).with('dresden')

    @client.delete_all_area_tags
  end

  should 'tag all models with area' do
    orga = build(:orga)
    orga.area = 'leipzig'
    orga.save(validate: false)

    orga2 = build(:orga)
    orga2.area = 'leipzig'
    orga2.save(validate: false)

    orga3 = build(:orga)
    orga3.area = 'dresden'
    orga3.save(validate: false)

    orga4 = build(:orga)
    orga4.area = 'bautzen'
    orga4.save(validate: false)

    result = mock()
    result.stubs(:records_affected).returns(2)
    PhraseApp::Client.any_instance.expects(:keys_tag).with do |project_id, params|
      next if params.tags != 'leipzig'
      keys = [
        "orga.#{orga.id}.title",
        "orga.#{orga.id}.short_description",
        "orga.#{orga2.id}.title",
        "orga.#{orga2.id}.short_description"
      ]
      assert_equal 'name:' + keys.join(','), params.q
    end
    .returns([result])

    result = mock()
    result.stubs(:records_affected).returns(4)
    PhraseApp::Client.any_instance.expects(:keys_tag).with do |project_id, params|
      next if params.tags != 'dresden'
      keys = [
        "orga.#{orga3.id}.title",
        "orga.#{orga3.id}.short_description"
      ]
      assert_equal params.q, 'name:' + keys.join(',')
    end
    .returns([result])

    result = mock()
    result.stubs(:records_affected).returns(2)
    PhraseApp::Client.any_instance.expects(:keys_tag).with do |project_id, params|
      next if params.tags != 'bautzen'
      keys = [
        "orga.#{orga4.id}.title",
        "orga.#{orga4.id}.short_description"
      ]
      assert_equal params.q, 'name:' + keys.join(',')
    end
    .returns([result])

    num_tagged = @client.tag_all_areas

    assert_equal 8, num_tagged
  end

  should 'delete translations of the given model' do
    orga = create(:orga)

    expect_deletes_key("orga.#{orga.id}.title")
    expect_deletes_key("orga.#{orga.id}.short_description")

    num_deletes = @client.delete_translation(orga)

    assert_equal 2, num_deletes
  end

  should 'sync all translations' do
    json = '{test:ok}'

    PhraseAppClient.any_instance.expects(:download_locale).returns(json)
    PhraseAppClient.any_instance.expects(:delete_unused_keys).with(json)
    PhraseAppClient.any_instance.expects(:add_missing_or_invalid_keys).with(json)
    PhraseAppClient.any_instance.expects(:delete_all_area_tags)
    PhraseAppClient.any_instance.expects(:tag_all_areas)

    @client.sync_all_translations
  end

  should 'delete all unused keys' do
    existing_orga = create(:orga)

    orga_whithout_title = build(:orga)
    orga_whithout_title.title = ''
    orga_whithout_title.save(validate: false)

    orga_whithout_short_description = build(:orga)
    orga_whithout_short_description.short_description = ''
    orga_whithout_short_description.save(validate: false)

    orga_whithout_attributes = build(:orga)
    orga_whithout_attributes.title = ''
    orga_whithout_attributes.short_description = ''
    orga_whithout_attributes.save(validate: false)

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
    orga_whithout_title.save(validate: false)

    orga_whithout_short_description = build(:orga)
    orga_whithout_short_description.title = 'orga_whithout_short_description'
    orga_whithout_short_description.save(validate: false)

    new_orga = build(:orga)
    new_orga.title = 'new_orga'
    new_orga.save(validate: false)

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
      .with(Settings.phraseapp.project_id, params)
      .returns([result])
  end

end
