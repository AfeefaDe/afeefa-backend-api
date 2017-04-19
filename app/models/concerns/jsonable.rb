module Jsonable

  extend ActiveSupport::Concern

  def default_hash
    @type ||= self.class.to_s.split('::').last.underscore.pluralize
    {
      type: @type,
      id: id.try(:to_s)
    }
  end

  def to_hash(attributes: self.class.default_attributes_for_json, relationships: self.class.default_relations_for_json)
    default_hash.tap do |hash|
      if attributes.present?
        json_attributes = {}
        [attributes].flatten.each do |attribute|
          attribute = attribute.to_sym
          next unless attribute.in?(self.class.attribute_whitelist_for_json)
          json_attributes[attribute.to_sym] =
            if respond_to?("#{attribute}_to_hash")
              send("#{attribute}_to_hash")
            else
              send(attribute)
            end
        end
        hash.merge!(attributes: json_attributes)
      end
      if relationships.present?
        json_relations = {}
        [relationships].flatten.each do |relation|
          relation = relation.to_sym
          next unless relation.in?(self.class.relation_whitelist_for_json)
          association = send(relation)
          association =
            if association.respond_to?(:map)
              association.map { |element| element.to_hash(attributes: nil, relationships: nil) }
            else
              association.try(:to_hash, attributes: nil, relationships: nil)
            end
          json_relations[relation.to_sym] = { data: association }
        end
        hash.merge!(relationships: json_relations)
      end
    end
  end

  def as_json(options = {})
    to_hash(
      attributes: options[:attributes] || self.class.attribute_whitelist_for_json,
      relationships: options[:relationships] || self.class.relation_whitelist_for_json)
  end

  module ClassMethods
    def attribute_whitelist_for_json
      # raise NotImplementedError, "attribute_whitelist_for_json must be defined for class #{self}"
      []
    end

    def relation_whitelist_for_json
      # raise NotImplementedError, "relation_whitelist_for_json must be defined for class #{self}"
      []
    end

    def default_attributes_for_json
      # raise NotImplementedError, "default_attributes_for_json must be defined for class #{self}"
      []
    end

    def default_relations_for_json
      # raise NotImplementedError, "default_relations_for_json must be defined for class #{self}"
      []
    end
  end

end
