module Afeefa
  class Entry < Base

    self.table_name = 'ddfa_main_domain_model_marketentry'

    belongs_to :parent, class_name: 'Afeefa::Entry', primary_key: :persistence_object_identifier, foreign_key: :parent_entry_id
    has_many :children, class_name: 'Afeefa::Entry', primary_key: :persistence_object_identifier, foreign_key: :parent_entry_id
    has_many :locations, class_name: 'Afeefa::Location', primary_key: :persistence_object_identifier, foreign_key: :market_entry_id
    belongs_to :category, class_name: 'Afeefa::Category', primary_key: :persistence_object_identifier, foreign_key: :category_id

  end
end
