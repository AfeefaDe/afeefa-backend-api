class Api::V1::BaseResource < JSONAPI::Resource

  class << self
    def verify_key(key, context = nil)
      if key.is_a?(Hash) && key.key?(:attributes)
        key
      else
        if key.is_a?(Hash)
          raise 'Actually we can not handle hashes without attribtues.'
        end
        super
      end
    end
  end

  def _replace_fields(field_data)
    ActiveRecord::Base.transaction do
      # initialize model
      super(field_data.reject { |key, _value| key.in?(%i(to_one to_many)) })
      _model.save #!

      # handle associations
      field_data[:to_one].each do |relationship_type, value|
        if value.nil?
          remove_to_one_link(relationship_type)
        else
          case value
            when Hash
              # if value.fetch(:id) && value.fetch(:type)
              #   replace_polymorphic_to_one_link(relationship_type.to_s, value.fetch(:id), value.fetch(:type))
              # elsif value.fetch(:type)
              #   # create polymorphic
              #   handle_associated_object_creation(:to_one, relationship_type, value)
              # else
              #   # create
                handle_associated_object_creation(:to_one, relationship_type, value)
              # end
            when Integer, String
              value = { id: value }
          end
        end
        # TODO: Does this work correctly?
        # binding.pry
        relationship_key_value = value[:id]
        replace_to_one_link(relationship_type, relationship_key_value)
      end if field_data[:to_one]

      field_data[:to_many].each do |relationship_type, values|
        # _model.send("#{relationship_type}=", [])
        values.each do |data|
          # next if data.key?(:id)
          handle_associated_object_creation(:to_many, relationship_type, data)
        end
        # binding.pry
        relationship_key_values = values.map { |v| v[:id] }
        replace_to_many_links(relationship_type, relationship_key_values)
      end if field_data[:to_many]
      # binding.pry
      # _model.save!
    end
  end

  def _replace_to_many_links(relationship_type, relationship_key_values, options)
    # binding.pry
    super
  end

  private

  def handle_associated_object_creation(association_type, relationship_type, values)
    sanitized_attributes =
      values[:attributes].reject { |attr, _value| attr.in?(%i(type __id__)) }
    associated_object =
      if values.key?(:id)
        relationship_type.to_s.singularize.camelcase.constantize.find(values[:id])
      else
        relationship_type.to_s.singularize.camelcase.constantize.new
      end
    associated_object.assign_attributes(sanitized_attributes)
    # binding.pry
    if association_type == :to_one
      _model.send("#{relationship_type}=", associated_object)
    elsif association_type == :to_many
      _model.send(relationship_type) << associated_object
    end
    associated_object.save #!
    values.merge!(id: associated_object.id)
  end

end
