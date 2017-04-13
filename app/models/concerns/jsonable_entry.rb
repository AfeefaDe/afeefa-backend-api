module JsonableEntry

  extend ActiveSupport::Concern

  included do
    include Jsonable

    def to_hash_additionals
      { active: state == StateMachine::ACTIVE.to_s }
    end

    private

    def short_relationships_for_json
      {
        annotations: { data: annotations.map { |orga| orga.to_hash(only_reference: true) } },
        category: { data: category.try(:to_hash, only_reference: true) },
        sub_category: { data: sub_category.try(:to_hash, only_reference: true) },
      }
    end

    def relationships_for_json
      short_relationships_for_json.merge(
        locations: { data: locations.map { |orga| orga.to_hash(only_reference: true) } },
        contact_infos: { data: contact_infos.map { |orga| orga.to_hash(only_reference: true) } }
      )
    end
  end

end
