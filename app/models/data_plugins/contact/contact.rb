module DataPlugins::Contact
  class Contact < ApplicationRecord

    # disable rails single table inheritance
    self.inheritance_column = :_type_disabled

    MAIN = 'main'.freeze
    SUB = 'sub'.freeze
    TYPES = [MAIN, SUB]

    include Jsonable

    # SCOPES
    scope :main, -> { where(type: MAIN) }
    scope :sub, -> { where(type: SUB) }

    # ASSOCIATIONS
    belongs_to :owner, polymorphic: true
    has_many :contact_persons, class_name: ::DataPlugins::Contact::ContactPerson
    has_many :locations, class_name: ::DataPlugins::Location::Location

    # VALIDATIONS
    validates :title, length: { maximum: 1000 }
    validates :web, length: { maximum: 1000 }
    validates :social_media, length: { maximum: 1000 }
    validates :spoken_languages, length: { maximum: 255 }
    validates :fax, length: { maximum: 255 }

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(fax opening_hours social_media spoken_languages web).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(owner contact_persons).freeze
      end
    end

  end
end
