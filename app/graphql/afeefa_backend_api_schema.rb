require 'types/mutation_type'

class AfeefaBackendApiSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
