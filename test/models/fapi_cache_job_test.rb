require "test_helper"

class FapiCacheJobTest < ActiveSupport::TestCase

  # FAPI integration

  should 'trigger fapi on entries for area job created' do
    FapiClient.any_instance.expects(:job_created)
    FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))
  end

  should 'trigger fapi on all entries for all areas job created' do
    FapiClient.any_instance.expects(:job_created).times(3)
    FapiCacheJob.new.update_all_entries_for_all_areas
  end

  should 'trigger fapi on facet item translation job created' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created).times(3)

    FapiCacheJob.new.update_entry_translation(facet_item, 'en')
  end

  should 'trigger fapi on facet item destroy job created' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created).times(4)

    facet_item.destroy!
  end

  should 'trigger fapi on navigation item destroy job created' do
    navigation_item = create(:fe_navigation_item, title: 'New Entry')
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created).times(2)

    navigation_item.destroy
  end

  # Job handling

  should 'create a job to update all area entries' do
    job = FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should 'create a job to update all entries of all entries' do
    jobs = FapiCacheJob.new.update_all_entries_for_all_areas

    Translatable::AREAS.each_with_index do |area, index|
      job = jobs[index]
      assert_fapi_cache_job(
        job: job,
        areaTitle: area,
        updated: true
      )
    end
  end

  should 'create a job to update all area translations' do
    job = FapiCacheJob.new.update_all_area_translations(Area.find_by(title: 'dresden'))

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      translated: true
    )
  end

  should 'create a job to update a specific area translation' do
    job = FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'de')

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      translated: true,
      language: 'de'
    )
  end

  should 'create a job to update a specific entry' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry(orga)

    assert_fapi_cache_job(
      job: job,
      entry: orga,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should 'create a job to translate a specific entry' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry_translation(orga, 'en')

    assert_fapi_cache_job(
      job: job,
      entry: orga,
      areaTitle: 'dresden',
      translated: true,
      language: 'en'
    )
  end

  should 'create a job to delete a specific entry' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.delete_entry(orga)

    assert_fapi_cache_job(
      job: job,
      entry: orga,
      areaTitle: 'dresden',
      deleted: true
    )
  end

  should 'create a job to update a specific navigation item' do
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry(navigation_item)

    assert_fapi_cache_job(
      job: job,
      entry: navigation_item.navigation,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should 'create a job to translate a specific navigation item' do
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry_translation(navigation_item, 'en')

    assert_fapi_cache_job(
      job: job,
      entry: navigation_item,
      areaTitle: 'dresden',
      translated: true,
      language: 'en'
    )
  end

  should 'create a job to delete a specific navigation item' do
    navigation_item = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.delete_entry(navigation_item)

    assert_fapi_cache_job(
      job: job,
      entry: navigation_item.navigation,
      areaTitle: 'dresden',
      updated: true
    )
  end

  should 'create a job to update a specific facet item' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry(facet_item)

    assert_fapi_cache_job(
      job: job,
      entry: facet_item.facet,
      updated: true
    )
  end

  should 'create a job to translate a specific facet item' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    jobs = FapiCacheJob.new.update_entry_translation(facet_item, 'en')

    Translatable::AREAS.each_with_index do |area, index|
      job = jobs[index]
      assert_fapi_cache_job(
        job: job,
        entry: facet_item,
        areaTitle: area,
        translated: true,
        language: 'en'
      )
    end
  end

  should 'create a job to delete a specific facet item' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.delete_entry(facet_item)

    assert_fapi_cache_job(
      job: job,
      entry: facet_item.facet,
      updated: true
    )
  end

  should 'not create a job to update or translate an area multiple times' do
    # update all entries
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))
    end

    # translate all languages
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area.find_by(title: 'dresden'))
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area.find_by(title: 'dresden'))
    end

    # translate specific language
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'de')
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'de')
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'en')
    end
  end

  should 'create a job to update or translate an area multiple times if existing job has already been started' do
    # update all entries
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area.find_by(title: 'dresden'))
    end

    # translate all languages
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_all_area_translations(Area.find_by(title: 'dresden'))
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area.find_by(title: 'dresden'))
    end

    # translate specific language
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'de')
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area.find_by(title: 'dresden'), 'de')
    end
  end

  should 'not create a job to update, delete or translate an entry multiple times' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    # update entry
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry(orga)
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry(orga)
    end

    # delete entry
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.delete_entry(orga)
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.delete_entry(orga)
    end

    # translate entry
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry_translation(orga, 'de')
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry_translation(orga, 'de')
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry_translation(orga, 'en')
    end
  end

  should 'create a job to update, delete or translate an entry multiple times if existing job has already been started' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    # update entry
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry(orga)
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry(orga)
    end

    # delete entry
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.delete_entry(orga)
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.delete_entry(orga)
    end

    # translate entry
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(orga, 'de')
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_entry_translation(orga, 'de')
    end
  end

  [:update, :delete].each do |operation|
    [:update, :delete].each do |operation2|
      should "merge all entry #{operation} #{operation2} jobs to an area job if another entry update job is present" do
        orga = create(:orga)
        orga2 = create(:orga)
        FapiCacheJob.delete_all

        assert_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation}_entry", orga)

          assert_fapi_cache_job(
            job: job,
            entry: orga,
            areaTitle: 'dresden',
            "#{operation}d".to_sym => true
          )
        end

        assert_no_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation}_entry", orga2)

          assert_fapi_cache_job(
            job: job,
            areaTitle: 'dresden',
            updated: true
          )
        end
      end
    end
  end

  [:update, :delete].each do |operation|
    [:update, :delete].each do |operation2|
      should "merge all navigation #{operation} #{operation2} jobs to an area job if another navigation update job is present" do
        navigation = create(:fe_navigation_with_items)
        navigation_item = navigation.navigation_items.first
        navigation2 = create(:fe_navigation_with_items)
        navigation_item2 = navigation2.navigation_items.first
        FapiCacheJob.delete_all

        assert_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation}_entry", navigation_item)

          assert_fapi_cache_job(
            job: job,
            entry: navigation,
            areaTitle: 'dresden',
            updated: true
          )
        end

        assert_no_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation2}_entry", navigation_item2)

          assert_fapi_cache_job(
            job: job,
            entry: navigation,
            areaTitle: 'dresden',
            updated: true
          )
        end
      end
    end
  end

  [:update, :delete].each do |operation|
    [:update, :delete].each do |operation2|
      should "merge all facet #{operation} #{operation2} jobs to an area job if another facet update job is present" do
        facet = create(:facet_with_items)
        facet_item = facet.facet_items.first
        facet2 = create(:facet_with_items)
        facet_item2 = facet2.facet_items.first
        FapiCacheJob.delete_all

        assert_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation}_entry", facet_item)

          assert_fapi_cache_job(
            job: job,
            entry: facet,
            updated: true
          )
        end

        assert_no_difference -> { FapiCacheJob.count } do
          job = FapiCacheJob.new.send("#{operation2}_entry", facet_item2)

          assert_fapi_cache_job(
            job: job,
            entry: facet,
            updated: true
          )
        end
      end
    end
  end

  should "merge all entry translation jobs to an area job if another entry translation job is present" do
    orga = create(:orga)
    orga2 = create(:orga)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(orga, 'de')

      assert_fapi_cache_job(
        job: job,
        entry: orga,
        areaTitle: 'dresden',
        translated: true,
        language: 'de'
      )
    end

    assert_no_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(orga2, 'de')

      assert_fapi_cache_job(
        job: job,
        areaTitle: 'dresden',
        translated: true,
        language: 'de'
      )
    end

    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(orga, 'ar')

      assert_fapi_cache_job(
        job: job,
        entry: orga,
        areaTitle: 'dresden',
        translated: true,
        language: 'ar'
      )
    end
  end

  should "merge all navigation translation jobs to an area job if another navigation translation job is present" do
    navigation_item = create(:fe_navigation_item)
    navigation_item2 = create(:fe_navigation_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(navigation_item, 'de')

      assert_fapi_cache_job(
        job: job,
        entry: navigation_item,
        areaTitle: 'dresden',
        translated: true,
        language: 'de'
      )
    end

    assert_no_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(navigation_item2, 'de')

      assert_fapi_cache_job(
        job: job,
        areaTitle: 'dresden',
        translated: true,
        language: 'de'
      )
    end

    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_entry_translation(navigation_item, 'fi')

      assert_fapi_cache_job(
        job: job,
        entry: navigation_item,
        areaTitle: 'dresden',
        translated: true,
        language: 'fi'
      )
    end
  end

  should "merge all facet translation jobs to an area job if another facet translation job is present" do
    facet_item = create(:facet_item)
    facet_item2 = create(:facet_item)
    FapiCacheJob.delete_all

    assert_difference -> { FapiCacheJob.count }, 3 do
      jobs = FapiCacheJob.new.update_entry_translation(facet_item, 'en')

      Translatable::AREAS.each_with_index do |area, index|
        job = jobs[index]
        assert_fapi_cache_job(
          job: job,
          entry: facet_item,
          areaTitle: area,
          translated: true,
          language: 'en'
        )
      end
    end

    assert_no_difference -> { FapiCacheJob.count } do
      jobs = FapiCacheJob.new.update_entry_translation(facet_item2, 'en')

      Translatable::AREAS.each_with_index do |area, index|
        job = jobs[index]
        assert_fapi_cache_job(
          job: job,
          areaTitle: area,
          translated: true,
          language: 'en'
        )
      end
    end

    assert_difference -> { FapiCacheJob.count }, 3 do
      jobs = FapiCacheJob.new.update_entry_translation(facet_item, 'us')

      Translatable::AREAS.each_with_index do |area, index|
        job = jobs[index]
        assert_fapi_cache_job(
          job: job,
          entry: facet_item,
          areaTitle: area,
          translated: true,
          language: 'us'
        )
      end
    end
  end

end
