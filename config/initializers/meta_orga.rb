if ActiveRecord::Migrator.get_all_versions.include? 20161029150323
  unless Orga.meta_orga
    raise 'META ORGA is missing!'
  end
end
