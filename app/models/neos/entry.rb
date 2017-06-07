module Neos
  class Entry < Base

    self.table_name = 'ddfa_main_domain_model_marketentry'

    belongs_to :parent, class_name: 'Neos::Entry',
      primary_key: :persistence_object_identifier, foreign_key: :parent_entry_id
    has_many :children, class_name: 'Neos::Entry',
      primary_key: :persistence_object_identifier, foreign_key: :parent_entry_id
    has_many :locations, -> { order('updated desc') }, class_name: 'Neos::Location',
      primary_key: :persistence_object_identifier, foreign_key: :market_entry_id
    belongs_to :category, class_name: 'Neos::Category',
      primary_key: :persistence_object_identifier, foreign_key: :category_id

    def orga?
      type == 0
    end

    def event?
      type == 2
    end

    def self.translatable_attributes
      %i(name description) #short_description
    end

  end
end
