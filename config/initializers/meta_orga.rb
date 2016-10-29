if ActiveRecord::Migrator.current_version >= 20161029150322
  unless Orga.meta_orga
    raise 'META ORGA is missing!'
  end
end
