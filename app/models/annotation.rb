class Annotation < ApplicationRecord

  has_many :annotation_able_relations
  has_many :events, through: :annotation_able_relations, source: :entry, source_type: 'Event'
  has_many :orgas, through: :annotation_able_relations, source: :entry, source_type: 'Orga'

end
