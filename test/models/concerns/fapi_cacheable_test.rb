require 'test_helper'

class FapiCacheableTest < ActiveSupport::TestCase

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on entry create for #{entry_factory}" do
      entry = nil

      assert_difference -> { FapiCacheJob.count } do
        entry = create(entry_factory)
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry: entry,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on entry update for #{entry_factory}" do
      entry = create(entry_factory)
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count }, 2 do
        entry.update!(title: 'neuer title')
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.first,
        entry: entry,
        areaTitle: 'dresden',
        translated: true,
        language: 'de'
      )

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry: entry,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on entry delete for #{entry_factory}" do
      entry = create(entry_factory)
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count } do
        entry.destroy!
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry_type: entry.class.name,
        entry_id: entry.id,
        areaTitle: 'dresden',
        deleted: true
      )
    end
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on contact create #{entry_factory}" do
      entry = create(entry_factory, contacts: [])
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count } do
        create_params = ActionController::Parameters.new(
          owner_type: entry_factory.to_s + 's',
          owner_id: entry.id,
          action: 'create',
          title: 'testkontakt'
        )

        entry.save_contact(create_params)
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry: entry,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on contact update #{entry_factory}" do
      entry = create(entry_factory)
      contact = create(:contact, owner: entry)
      entry.update!(contact_id: contact.id)
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count } do
        update_params = ActionController::Parameters.new(
          owner_type: entry_factory.to_s + 's',
          owner_id: entry.id,
          id: contact.id,
          action: 'update'
        )

        entry.save_contact(update_params)
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry: entry,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end

  [:orga, :event, :offer].each do |entry_factory|
    should "add cache job on contact destroy #{entry_factory}" do
      entry = create(entry_factory)
      contact = create(:contact, owner: entry)
      entry.update!(contact_id: contact.id)
      # entry.reload
      # contact.reload
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count } do
        delete_params = ActionController::Parameters.new(
          id: contact.id
        )

        entry.delete_contact(delete_params)
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        entry: entry,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end

  should "add cache job on navigation item create" do
    navigation_item = nil

    assert_difference -> { FapiCacheJob.count } do
      navigation_item = create(:fe_navigation_item)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: navigation_item.navigation,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on navigation item update" do
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count }, 2 do
      navigation_item.update(title: 'new title')
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.first,
      entry: navigation_item,
      areaTitle: 'dresden',
      translated: true,
      language: 'de'
    )

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: navigation_item.navigation,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on navigation item destroy" do
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count }, 2 do
      navigation_item.destroy!
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.first,
      entry: navigation_item.navigation,
      areaTitle: 'dresden',
      updated: true
    )

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on facet item create" do
    facet_item = nil

    assert_difference -> { FapiCacheJob.count } do
      facet_item = create(:facet_item)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: facet_item.facet,
      updated: true
    )
  end

  should "add cache job on facet item update" do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count }, 4 do
      facet_item.update(title: 'new title')
    end

    jobs = FapiCacheJob.all

    Translatable::AREAS.each_with_index do |areaTitle, index|
      assert_fapi_cache_job(
        job: jobs[index],
        entry: facet_item,
        areaTitle: areaTitle,
        translated: true,
        language: 'de'
      )
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: facet_item.facet,
      updated: true
    )
  end

  should "add cache job on facet item destroy" do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count }, 4 do
      facet_item.destroy!
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.first,
      entry: facet_item.facet,
      updated: true
    )

    jobs = FapiCacheJob.all

    Translatable::AREAS.each_with_index do |areaTitle, index|
      assert_fapi_cache_job(
        job: jobs[index + 1],
        areaTitle: areaTitle,
        updated: true
      )
    end

  end

  should "add cache job on owner link facet_item" do
    orga = create(:orga)
    facet = create(:facet, owner_types: ['Orga'])
    facet_item = create(:facet_item, facet: facet)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      facet_item.link_owner(orga)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: orga,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on owner unlink facet_item" do
    orga = create(:orga)
    facet = create(:facet, owner_types: ['Orga'])
    facet_item = create(:facet_item, facet: facet)
    facet_item.link_owner(orga)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      facet_item.unlink_owner(orga)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: orga,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on owner link navigation_item" do
    orga = create(:orga)
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      navigation_item.link_owner(orga)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: orga,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should "add cache job on owner unlink navigation_item" do
    orga = create(:orga)
    navigation_item = create(:fe_navigation_item)
    navigation_item.link_owner(orga)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      navigation_item.unlink_owner(orga)
    end

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      entry: orga,
      areaTitle: 'dresden',
      updated: true
    )
  end

  DataModules::Actor::ActorRelation::ASSOCIATION_TYPES.each do |association_type|
    should "add cache job on actor relation #{association_type} created" do
      orga = create(:orga)
      orga2 = create(:orga)
      FapiCacheJob.delete_all

      assert_difference -> { FapiCacheJob.count }, 1 do
        DataModules::Actor::ActorRelation.create(
          associating_actor: orga,
          associated_actor: orga2,
          type: association_type
        )
      end

      assert_fapi_cache_job(
        job: FapiCacheJob.last,
        areaTitle: 'dresden',
        updated: true
      )
    end
  end


end