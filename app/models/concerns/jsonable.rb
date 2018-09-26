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
      dependent_relationships: {},
      dependent_attributes: {},
      type: nil, public: false)

      default_hash(type: type).tap do |hash|

      # attributes
      if attributes.present?
        json_attributes = {}
        [attributes].flatten.each do |attribute|
          attribute = attribute.to_sym
          whitelist =
            if public
              self.class.public_attribute_whitelist_for_json
            else
              self.class.attribute_whitelist_for_json
            end
          next unless attribute.in?(whitelist)

          # count relation attribute
          is_count_relation_attribute = false
          match_count_relation = /^count_(.+)/.match(attribute.to_s)
          if match_count_relation
            relation = match_count_relation[1].to_sym
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
          whitelist =
            if public
              self.class.public_relation_whitelist_for_json
            else
              self.class.relation_whitelist_for_json
            end
          next unless relation.in?(whitelist)

          to_hash_params = {}
          if dependent_relationships.has_key?(relation)
            to_hash_params[:relationships] = dependent_relationships.try(:[], relation)
          end
          if dependent_attributes.has_key?(relation)
            to_hash_params[:attributes] = dependent_attributes.try(:[], relation)
          end

          association =
            if respond_to?("#{relation}_to_hash")
              skip_to_hash = true
              send("#{relation}_to_hash", to_hash_params)
            else
              skip_to_hash = false
              send(relation)
            end

          unless skip_to_hash
            to_hash_params.merge!(attributes: nil)

            association =
              if association.respond_to?(:map)
                association.map { |element| element.to_hash(to_hash_params) }
              else
                association.try(:to_hash, to_hash_params)
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
      relationships: options[:relationships] || self.class.relation_whitelist_for_json,
      public: options[:public] || false
    )
  end

  module ClassMethods
    def public_attribute_whitelist_for_json
      default_attributes_for_json - %i(created_at updated_at active)
    end

    def public_relation_whitelist_for_json
      default_relations_for_json - %i(creator last_editor annotations)
    end

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
