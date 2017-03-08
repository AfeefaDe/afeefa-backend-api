if ActiveRecord::Migrator.get_all_versions.include? 20161030102105
  unless Orga.root_orga
    fail 'ROOT ORGA is missing!'
  end
end
