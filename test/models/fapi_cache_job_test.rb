require "test_helper"

class FapiCacheJobTest < ActiveSupport::TestCase

  # FAPI integration

  test 'trigger fapi on entries for area job created' do
    FapiClient.any_instance.expects(:job_created)
    FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
  end

  test 'trigger fapi on all entries for all areas job created' do
    FapiClient.any_instance.expects(:job_created)
    FapiCacheJob.new.update_all_entries_for_all_areas
  end

  test 'trigger fapi on facet item translation job created' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_entry_translation(facet_item, 'en')
  end

  test 'trigger fapi on facet item destroy job created' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created).times(2)

    facet_item.destroy!
  end

  test 'trigger fapi on navigation item destroy job created' do
    navigation_item = create(:fe_navigation_item, title: 'New Entry')
    FapiCacheJob.delete_all

    FapiClient.any_instance.expects(:job_created).times(2)

    navigation_item.destroy
  end


  test 'trigger fapi anyway, even if the same job has already been scheduled - update_all' do
    # update_all_entries_for_area
    FapiCacheJob.new.update_all

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_all
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_all_entries_for_area' do
    # update_all_entries_for_area
    FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_entry_translation' do
    # update_entry_translation
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all
    FapiCacheJob.new.update_entry_translation(facet_item, 'en')

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_entry_translation(facet_item, 'en')
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_all_entries_for_all_areas' do
    # update_all_entries_for_all_areas
    FapiCacheJob.new.update_all_entries_for_all_areas

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_all_entries_for_all_areas
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_all_area_translations' do
    # update_all_area_translations
    FapiCacheJob.new.update_all_area_translations(Area['dresden'])

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_all_area_translations(Area['dresden'])
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_area_translation' do
    # update_area_translation
    FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - update_entry' do
    # update_entry
    orga = create(:orga)
    FapiCacheJob.delete_all

    FapiCacheJob.new.update_entry(orga)

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.update_entry(orga)
  end

  test 'trigger fapi anyway, even if the same job has already been scheduled - delete_entry' do
    # delete_entry
    orga = create(:orga)
    FapiCacheJob.delete_all

    FapiCacheJob.new.delete_entry(orga)

    FapiClient.any_instance.expects(:job_created)

    FapiCacheJob.new.delete_entry(orga)
  end

  # Job handling

  test 'create a job to update all' do
    job = FapiCacheJob.new.update_all

    assert_fapi_cache_job(
      job: job,
      updated: true,
      translated: true
    )
  end

  test 'not create a job to update all multiple times' do
    job = FapiCacheJob.new.update_all

    assert_fapi_cache_job(
      job: job,
      updated: true,
      translated: true
    )

    assert_no_difference -> { FapiCacheJob.count } do
      job2 = FapiCacheJob.new.update_all
      assert_equal job, job2
    end

  end

  test 'remove all other jobs if update all is scheduled' do
    orga = create(:orga)
    FapiCacheJob.delete_all

    FapiCacheJob.new.update_entry(orga)
    FapiCacheJob.new.update_entry_translation(orga, 'en')
    FapiCacheJob.new.update_entry_translation(orga, 'de')
    FapiCacheJob.new.update_entry_translation(orga, 'fr')

    assert_equal 4, FapiCacheJob.count

    assert_difference -> { FapiCacheJob.count }, -3 do
      FapiCacheJob.new.update_all

    end

    assert_equal 1, FapiCacheJob.count

    assert_fapi_cache_job(
      job: FapiCacheJob.last,
      updated: true,
      translated: true
    )
  end

  test 'create a job to update all area entries' do
    job = FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      updated: true
    )
  end

  test 'create a job to update all entries of all entries' do
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

  test 'create a job to update all area translations' do
    job = FapiCacheJob.new.update_all_area_translations(Area['dresden'])

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      translated: true
    )
  end

  test 'create a job to update a specific area translation' do
    job = FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')

    assert_fapi_cache_job(
      job: job,
      areaTitle: 'dresden',
      translated: true,
      language: 'de'
    )
  end

  test 'create a job to update a specific entry' do
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

  test 'create a job to translate a specific entry' do
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

  test 'create a job to delete a specific entry' do
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

  test 'create a job to update a specific navigation item' do
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

  test 'create a job to translate a specific navigation item' do
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

  test 'create a job to delete a specific navigation item' do
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

  test 'create a job to update a specific facet item' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.update_entry(facet_item)

    assert_fapi_cache_job(
      job: job,
      entry: facet_item.facet,
      updated: true
    )
  end

  test 'create a job to translate a specific facet item' do
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

  test 'create a job to delete a specific facet item' do
    facet_item = create(:facet_item)
    FapiCacheJob.delete_all

    job = FapiCacheJob.new.delete_entry(facet_item)

    assert_fapi_cache_job(
      job: job,
      entry: facet_item.facet,
      updated: true
    )
  end

  test 'not create a job to update or translate an area multiple times' do
    # update all entries
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
    end

    # translate all languages
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area['dresden'])
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area['dresden'])
    end

    # translate specific language
    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')
    end

    assert_no_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area['dresden'], 'en')
    end
  end

  test 'create a job to update or translate an area multiple times if existing job has already been started' do
    # update all entries
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_entries_for_area(Area['dresden'])
    end

    # translate all languages
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_all_area_translations(Area['dresden'])
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_all_area_translations(Area['dresden'])
    end

    # translate specific language
    assert_difference -> { FapiCacheJob.count } do
      job = FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')
      job.update!(started_at: Time.now)
    end

    assert_difference -> { FapiCacheJob.count } do
      FapiCacheJob.new.update_area_translation(Area['dresden'], 'de')
    end
  end

  test 'not create a job to update, delete or translate an entry multiple times' do
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

  test 'create a job to update, delete or translate an entry multiple times if existing job has already been started' do
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
      test "merge all entry #{operation} #{operation2} jobs to an area job if another entry update job is present" do
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
      test "merge all navigation #{operation} #{operation2} jobs to an area job if another navigation update job is present" do
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
      test "merge all facet #{operation} #{operation2} jobs to an area job if another facet update job is present" do
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

  test "merge all entry translation jobs to an area job if another entry translation job is present" do
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

  test "merge all navigation translation jobs to an area job if another navigation translation job is present" do
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

  test "merge all facet translation jobs to an area job if another facet translation job is present" do
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
