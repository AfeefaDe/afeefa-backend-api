module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :actors, ActorType, null: true do
      argument :limit, String,
        required: false,
        default_value: 20,
        prepare: -> (limit, _context) { [limit, 30].min }
    end

    def actors(limit)
      Orga.active.limit(limit)
    end

    # TODO: remove me
    field :test_field, String, null: false,
      description: 'An example field added by the generator'

    def test_field
      'Hello World!'
    end
  end
end
