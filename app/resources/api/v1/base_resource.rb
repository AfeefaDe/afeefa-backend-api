class Api::V1::BaseResource < JSONAPI::Resource

  class << self
    def verify_key(key, context = nil)
      if key.is_a?(Hash) && key.key?(:attributes)
        key
      else
        super
      end
    end
  end

  def _replace_fields(field_data)
    # initialize model
    super(field_data.reject { |key, _value| key.in?(%i(to_one to_many)) })
    _model.save

    # handle associations
    field_data[:to_one].each do |relationship_type, value|
      if value.nil?
        remove_to_one_link(relationship_type)
      else
        case value
          when Hash
            if value.fetch(:id) && value.fetch(:type)
              replace_polymorphic_to_one_link(relationship_type.to_s, value.fetch(:id), value.fetch(:type))
            elsif value.fetch(:type)
              # create polymorphic
            else
              # create
            end
          else
            replace_to_one_link(relationship_type, value)
        end
      end
    end if field_data[:to_one]

    field_data[:to_many].each do |relationship_type, values|
      existing_elements =
        values.select do |value|
          value.key?(:id)
        end
      not_existing_values = values - existing_elements

      not_existing_values.each do |attributes|
        sanitized_attributes =
          attributes[:attributes].reject { |attr, _value| attr.in?(%i(type __id__)) }
        associated_object =
          relationship_type.to_s.singularize.camelcase.constantize.new(sanitized_attributes)
        _model.send(relationship_type) << associated_object
        associated_object.save
      end
    end if field_data[:to_many]
  end

end
