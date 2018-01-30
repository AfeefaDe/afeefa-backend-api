module Jsonable

  extend ActiveSupport::Concern

  def default_hash(type: nil)
    type ||= self.class.to_s.split('::').last.underscore.pluralize
    {
      type: type,
      id: id.try(:to_s)
    }
  end

  def to_hash(
      attributes: self.class.default_attributes_for_json,
      relationships: self.class.default_relations_for_json,
      type: nil)

      default_hash(type: type).tap do |hash|

      # attributes
      if attributes.present?
        json_attributes = {}
        [attributes].flatten.each do |attribute|
          attribute = attribute.to_sym
          next unless attribute.in?(self.class.attribute_whitelist_for_json)

          # count relation attribute
          is_count_relation_attribute = false
          matchCountRelation = /^count_(.+)/.match(attribute.to_s)
          if matchCountRelation
            relation = matchCountRelation[1].to_sym
            if relation.in?(self.class.count_relation_whitelist_for_json)
              json_attributes[attribute.to_sym] = send(relation).length
              is_count_relation_attribute = true
            end
          end

          # proper attribute
          unless is_count_relation_attribute
            json_attributes[attribute.to_sym] =
              if respond_to?("#{attribute}_to_hash")
                send("#{attribute}_to_hash")
              else
                send(attribute)
              end
          end
        end
        hash.merge!(attributes: json_attributes)
      end

      # relations
      if relationships.present?
        json_relations = {}
        [relationships].flatten.each do |relation|
          relation = relation.to_sym
          next unless relation.in?(self.class.relation_whitelist_for_json)

          association =
            if respond_to?("#{relation}_to_hash")
              skip_to_hash = true
              send("#{relation}_to_hash")
            else
              skip_to_hash = false
              send(relation)
            end

          unless skip_to_hash
            association =
              if association.respond_to?(:map)
                association.map { |element| element.to_hash(attributes: nil, relationships: nil) }
              else
                association.try(:to_hash, attributes: nil, relationships: nil)
              end
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

    def count_relation_whitelist_for_json
      # raise NotImplementedError, "count_relation_whitelist_for_json must be defined for class #{self}"
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
