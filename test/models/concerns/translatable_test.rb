require 'test_helper'

class TranslatableTest < ActiveSupport::TestCase

  test 'not update phraseapp translation if force flag is not set' do
    orga = build(:orga)

    orga.expects(:update_or_create_translations).never

    orga.save
  end

  test 'not upload translation if no attributes are changed' do
    orga = create(:orga)

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    orga.update_or_create_translations
  end

  test 'build json for phraseapp' do
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

  test 'create translation on entry create' do
    orga = build(:orga, title: 'testorga')
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      orga_id = Orga.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['orga']
      assert_not_nil json['orga'][orga_id]
      assert_equal 'testorga', json['orga'][orga_id]['title']
      assert_equal 'this is the short description', json['orga'][orga_id]['short_description']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert orga.save
  end

  test 'create translation on facet_item create' do
    facet_item = build(:facet_item, title: 'New Category')
    facet_item.force_translation_after_save = true
    facet_item.facet.save!

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      facet_item_id = DataPlugins::Facet::FacetItem.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['facet_item']
      assert_not_nil json['facet_item'][facet_item_id]
      assert_equal 'New Category', json['facet_item'][facet_item_id]['title']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_nil tags_hash
    end

    facet_item.save!
  end

  test 'create translation on navigation_item create' do
    navigation_item = build(:fe_navigation_item, title: 'New Navigation Item')
    navigation_item.force_translation_after_save = true
    navigation_item.navigation.save!

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      navigation_item_id = DataModules::FeNavigation::FeNavigationItem.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['navigation_item']
      assert_not_nil json['navigation_item'][navigation_item_id]
      assert_equal 'New Navigation Item', json['navigation_item'][navigation_item_id]['title']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    navigation_item.save!
  end

  test 'not create translation on entry create if related attributes are empty' do
    orga = build(:orga)
    orga.force_translation_after_save = true
    orga.title = ''
    orga.short_description = ''

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    assert orga.save(validate: false)
  end

  test 'only create translation for nonempty attributes on entry create' do
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

  test 'set area tag on create translation' do
    orga = build(:orga)
    orga.area = 'heinz_landkreis'
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      assert_equal 'heinz_landkreis', tags_hash[:tags]
    end

    assert orga.save
  end

  test 'update translation on entry update' do
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

  test 'update translation on facet_item update' do
    facet_item = create(:facet_item, title: 'New Category')
    facet_item_id = facet_item.id.to_s
    facet_item.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['facet_item']
      assert_not_nil json['facet_item'][facet_item_id]
      assert_equal 'Super Category', json['facet_item'][facet_item_id]['title']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_nil tags_hash
    end

    assert facet_item.update(title: 'Super Category')
  end

  test 'update translation on navigation_item update' do
    navigation_item = create(:fe_navigation_item, title: 'New Navigation Entry')
    navigation_item_id = navigation_item.id.to_s
    navigation_item.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['navigation_item']
      assert_not_nil json['navigation_item'][navigation_item_id]
      assert_equal 'Homepage', json['navigation_item'][navigation_item_id]['title']

      assert_equal Translatable::DEFAULT_LOCALE, phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert navigation_item.update(title: 'Homepage')
  end

  test 'set area tag on update translation' do
    orga = create(:orga)
    orga.area = 'heinz_landkreis'
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).with do |file, phraseapp_locale_id, tags_hash|
      assert_equal 'heinz_landkreis', tags_hash[:tags]
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  test 'update translation on entry update only once' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).once.with do |file, phraseapp_locale_id, tags_hash|
      assert true
    end

    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
    assert orga.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  test 'not update translation on entry update if all related attributes are empty' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:upload_translation_file_for_locale).never

    orga.assign_attributes(title: '', short_description: '')
    assert orga.save(validate: false)
  end

  test 'only update translation for nonempty attributes on entry update' do
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

  test 'remove translations of all attributes on entry delete' do
    orga = create(:orga)
    orga.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:delete_translation).with do |orga_to_delete|
      assert_equal orga, orga_to_delete
    end

    assert orga.destroy
  end

  test 'remove translations of all attributes on facet_item delete' do
    facet_item = create(:facet_item, title: 'New Category')
    facet_item.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:delete_translation).with do |facet_item_to_delete|
      assert_equal facet_item, facet_item_to_delete
    end

    assert facet_item.destroy
  end

  test 'remove translations of all attributes on navigation_item delete' do
    navigation_item = create(:fe_navigation_item, title: 'Best Page')
    navigation_item.force_translation_after_save = true

    PhraseAppClient.any_instance.expects(:delete_translation).with do |navigation_item_to_delete|
      assert_equal navigation_item, navigation_item_to_delete
    end

    assert navigation_item.destroy
  end

  # fapi cache integration

  [:orga, :event, :offer].each do |entry_factory|
    should "create fapi cache job on entry create for #{entry_factory}" do
      entry = build(entry_factory)

      FapiCacheJob.any_instance.expects(:update_entry_translation).never

      entry.save!
    end
  end

  test 'create fapi cache job if facet item is created' do
    facet_item = build(:facet_item, title: 'New Category')
    facet_item.facet.save!

    FapiCacheJob.any_instance.expects(:update_entry_translation).never

    facet_item.save!
  end

  test 'create fapi cache job if navigation item is created' do
    navigation_item = build(:fe_navigation_item, title: 'New Entry')
    navigation_item.navigation.save!

    FapiCacheJob.any_instance.expects(:update_entry_translation).never

    navigation_item.save!
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "create fapi cache job on entry update for #{entry_factory}" do
      entry = create(entry_factory)

      FapiCacheJob.any_instance.expects(:update_entry_translation).with(entry, 'de')

      entry.update!(title: 'new title')
    end
  end

  test 'create fapi cache job if facet item is updated' do
    facet_item = create(:facet_item, title: 'New Category')

    FapiCacheJob.any_instance.expects(:update_entry_translation).with(facet_item, 'de')

    facet_item.update!(title: 'new title')
  end

  test 'create fapi cache job if navigation item is updated' do
    navigation_item = create(:fe_navigation_item, title: 'New Entry')

    FapiCacheJob.any_instance.expects(:update_entry_translation).with(navigation_item, 'de')

    navigation_item.update!(title: 'new title')
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "create fapi cache job on entry delete for #{entry_factory}" do
      entry = create(entry_factory)

      FapiCacheJob.any_instance.expects(:update_entry_translation).never

      entry.destroy
    end
  end

  test 'create fapi cache job if facet item is deleted' do
    facet_item = create(:facet_item, title: 'New Category')

    FapiCacheJob.any_instance.expects(:update_entry_translation).never

    facet_item.destroy
  end

  test 'create fapi cache job if navigation item is deleted' do
    navigation_item = create(:fe_navigation_item, title: 'New Entry')

    FapiCacheJob.any_instance.expects(:update_entry_translation).never

    navigation_item.destroy
  end

end
