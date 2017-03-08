class Api::V1::BaseResource < JSONAPI::Resource

  class << self
    def verify_key(key, context = nil)
      if key.is_a?(Hash)
        if key.key?(:attributes)
          key
        else
          if key.key?(:id)
            key = key[:id]
            super
          else
            fail 'Actually we can not handle hashes without attribtues.'
          end
        end
      else
        super
      end
    end
  end

  def _replace_fields(field_data)
    ActiveRecord::Base.transaction do
      # initialize model
      super(field_data.reject { |key, _value| key.in?(%i(to_one to_many)) })
      # binding.pry
      _model.save # TODO: save!

      # handle associations
      field_data[:to_one].each do |relationship_type, value|
        if value.nil?
          remove_to_one_link(relationship_type)
        else
          case value
            when Hash
              if value.fetch(:id) && value.fetch(:type)
                replace_polymorphic_to_one_link(relationship_type.to_s, value.fetch(:id), value.fetch(:type))
                # TODO: Do we need that? Is it possible to create polymorphic objects? → Maybe locatable, contactable?
                # elsif value.fetch(:type)
                #   # create polymorphic
                #   handle_associated_object_creation(:to_one, relationship_type, value)
              else
                # create
                handle_associated_object_creation(:to_one, relationship_type, value)
              end
            when Integer, String
              value = { id: value }
          end
          # TODO: Does this work correctly?
          relationship_key_value = value[:id]
          replace_to_one_link(relationship_type, relationship_key_value)
        end
      end if field_data[:to_one]

      field_data[:to_many].each do |relationship_type, values|
        _model.send("#{relationship_type}=", [])
        values.map! do |data|
          handle_associated_object_creation(:to_many, relationship_type, data)
        end
        relationship_key_values = values.map { |v| v[:id] }
        replace_to_many_links(relationship_type, relationship_key_values)
      end if field_data[:to_many]
    end
  end

  def _replace_to_many_links(relationship_type, relationship_key_values, options)
    super
  end

  private

  def handle_associated_object_creation(association_type, relationship_type, values)
    if values.is_a?(Fixnum)
      values = { id: values }
    end
    sanitized_attributes = sanitize_attributes(values)
    # binding.pry if (values[:attributes].presence || {}).keys.include?(:__id__)
    associated_object =
      if values.key?(:id)
        relationship_type.to_s.singularize.camelcase.constantize.find(values[:id])
      else
        relationship_type.to_s.singularize.camelcase.constantize.new
      end
    associated_object.assign_attributes(sanitized_attributes)
    if association_type == :to_one
      _model.send("#{relationship_type}=", associated_object)
    elsif association_type == :to_many
      _model.send(relationship_type) << associated_object
    end
    # binding.pry
    associated_object.save # TODO: save!
    values.merge!(id: associated_object.id)
  end

  def sanitize_attributes(values)
    attributes =
      (values[:attributes].presence || {}).reject { |attr, _value| attr.in?(%i(type)) }
    if attributes.key?(:__id__)
      attributes[:internal_id] = attributes.delete(:__id__)
    end
    attributes
  end

end
