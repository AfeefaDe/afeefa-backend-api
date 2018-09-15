class FapiCacheJob < ApplicationRecord

  belongs_to :entry, polymorphic: true
  belongs_to :area

  scope :is_update_or_delete_entry_job, -> {
    where.not(updated: nil).
    or(where.not(deleted: nil))
  }

  scope :not_started, -> { where(started_at: nil) }

  scope :by_area, ->(area) { where(area: area) }

  scope :not_for_entry, ->(entry) { # https://github.com/rails/rails/issues/16983
    where("entry_type != ? or entry_type is null or entry_id != ? or entry_id is null",
      entry.class.name, entry.id)
  }

  after_commit on: [:create] do
    fapi_client = FapiClient.new
    fapi_client.job_created
  end

  def update_all
    existing_jobs = FapiCacheJob.
      not_started.
      where("area_id is not null or entry_type is not null")

    if existing_jobs.any?
      existing_jobs.delete_all
    end

    job = FapiCacheJob.not_started.find_by(entry: nil, area: nil, updated: true, translated: true)
    unless job
      job = FapiCacheJob.create!(updated: true, translated: true)
    end
    job
  end

  def update_all_entries_for_area(area)
    job = FapiCacheJob.not_started.find_by(entry: nil, area: area, updated: true)
    unless job
      job = FapiCacheJob.create!(area: area, updated: true)
    end
    job
  end

  def update_all_entries_for_all_areas
    jobs = []
    Translatable::AREAS.each do |areaTitle|
      area =  Area.find_by(title: areaTitle)
      jobs << update_all_entries_for_area(area)
    end
    jobs
  end

  def update_all_area_translations(area)
    job = FapiCacheJob.not_started.find_by(entry: nil, area: area, translated: true)
    unless job
      job = FapiCacheJob.create!(area: area, translated: true)
    end
    job
  end

  def update_area_translation(area, language)
    job = FapiCacheJob.not_started.find_by(entry: nil, area: area, translated: true, language: language)
    unless job
      job = FapiCacheJob.create!(area: area, translated: true, language: language)
    end
    job
  end

  def update_entry(entry)
    job = nil
    area = entry.respond_to?(:area) ? Area.find_by(title: entry.area) : nil

    if entry.is_a? DataModules::FeNavigation::FeNavigationItem
      # do not allow more than one update/delete job at a time
      job = ensure_not_more_than_one_navigation_update_job_per_area(area)
      entry = entry.navigation
    elsif entry.is_a? DataPlugins::Facet::FacetItem
      # do not allow more than one update/delete job at a time
      job = ensure_not_more_than_one_facet_update_job
      entry = entry.facet
    else
      # do not allow more than one update/delete job at a time
      job = ensure_not_more_than_one_entry_update_job_per_area(area, entry)
    end

    unless job
      job = FapiCacheJob.find_by(entry: entry, updated: true, started_at: nil)
      unless job
        job = FapiCacheJob.create!(entry: entry, area: area, updated: true)
      end
    end

    job
  end

  def delete_entry(entry)
    if entry.is_a? DataModules::FeNavigation::FeNavigationItem
      return update_entry(entry)
    end

    if entry.is_a? DataPlugins::Facet::FacetItem
      return update_entry(entry)
    end

    area = Area.find_by(title: entry.area)

    # do not allow more than one update/delete job at a time
    job = ensure_not_more_than_one_entry_update_job_per_area(area, entry)

    unless job
      job = FapiCacheJob.not_started.find_by(entry: entry, deleted: true)
      unless job
        area = Area.find_by(title: entry.area)
        job = FapiCacheJob.create!(entry: entry, area: area, deleted: true)
      end
    end

    job
  end

  def update_entry_translation(entry, language)
    if entry.is_a? DataPlugins::Facet::FacetItem
      return update_facet_item_translation(entry, language)
    end

    job = nil
    area = Area.find_by(title: entry.area)

    job = ensure_not_more_than_one_entry_translation_per_area_and_language(area, entry, language)

    unless job
      job = FapiCacheJob.not_started.find_by(entry: entry, area: area, translated: true, language: language)
      unless job
        job = FapiCacheJob.create!(entry: entry, area: area, translated: true, language: language)
      end
    end
    job
  end

  private

  def update_facet_item_translation(entry, language)
    jobs = []
    Translatable::AREAS.each do |areaTitle|
      area =  Area.find_by(title: areaTitle)
      job = update_entry_translation_for_area(area, entry, language)
      jobs << job unless jobs.include?(job)
    end
    jobs
  end

  def update_entry_translation_for_area(area, entry, language)
    job = nil

    job = ensure_not_more_than_one_entry_translation_per_area_and_language(area, entry, language)

    unless job
      job = FapiCacheJob.not_started.find_by(entry: entry, area: area, translated: true, language: language)
      unless job
        job = FapiCacheJob.create!(entry: entry, area: area, translated: true, language: language)
      end
    end
    job
  end

  def ensure_not_more_than_one_entry_translation_per_area_and_language(area, entry, language)
    existing_jobs = FapiCacheJob.
      by_area(area).
      not_started.
      where(translated: true, language: language).
      not_for_entry(entry)

    if existing_jobs.any?
      existing_jobs.delete_all
      return update_area_translation(area, language)
    end
  end

  def ensure_not_more_than_one_entry_update_job_per_area(area, entry)
    existing_jobs = FapiCacheJob.
      by_area(area).
      not_started.
      is_update_or_delete_entry_job

    if entry
      existing_jobs = existing_jobs.not_for_entry(entry)
    end

    if existing_jobs.any?
      existing_jobs.delete_all
      return update_all_entries_for_area(area)
    end
  end

  def ensure_not_more_than_one_navigation_update_job_per_area(area)
    FapiCacheJob.
      by_area(area).
      not_started.
      is_update_or_delete_entry_job.
      where(entry_type: DataModules::FeNavigation::FeNavigation.name).
      first
  end

  def ensure_not_more_than_one_facet_update_job
    FapiCacheJob.
      not_started.
      is_update_or_delete_entry_job.
      where(entry_type: DataPlugins::Facet::Facet.name).
      first
  end

end
