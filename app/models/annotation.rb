class Annotation < ApplicationRecord

  include Jsonable

  has_many :todos
  has_many :events, through: :todos, source: :entry, source_type: 'Event'
  has_many :orgas, through: :todos, source: :entry, source_type: 'Orga'

  private

  def relationships_for_json
    {}
  end

  def short_relationships_for_json
    {}
  end

end
