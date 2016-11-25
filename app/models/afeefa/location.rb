module Afeefa
  class Location < Base

    self.table_name = 'ddfa_main_domain_model_location'
    belongs_to :entry, class_name: 'Afeefa::Entry', primary_key: :persistence_object_identifier, foreign_key: :market_entry_id

  end
end
