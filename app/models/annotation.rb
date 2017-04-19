class Annotation < ApplicationRecord

  include Jsonable

  has_many :todos
  has_many :events, through: :todos, source: :entry, source_type: 'Event'
  has_many :orgas, through: :todos, source: :entry, source_type: 'Orga'

end
