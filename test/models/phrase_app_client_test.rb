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

  should 'delete translations of the given model' do
    orga = create(:orga)

    expect_deletes_key("orga.#{orga.id}.title")
    expect_deletes_key("orga.#{orga.id}.short_description")

    num_deletes = @client.delete_translation(orga)

    assert_equal 2, num_deletes
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

    num_deletes = @client.delete_unused_keys

    assert_equal 5, num_deletes
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

  should 'download locale file' do
    VCR.use_cassette('download_locale_en') do
      json = @client.send(:download_locale, 'en')
      assert_equal ['event', 'orga'], json.keys
    end
  end

end
