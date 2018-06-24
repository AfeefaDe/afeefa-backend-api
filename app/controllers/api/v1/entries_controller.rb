class Api::V1::EntriesController < Api::V1::EntriesBaseController

  include Search

  private

  def base_for_find_objects
    Entry.with_entries
  end

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(area any address contact_info).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
      when :area
        objects.
          where("orgas.#{filter} = ? OR events.#{filter} = ?",
            filter_criterion, filter_criterion)
      when :title, :description, :short_description
        raise 'We should no longer come here.'
      when :address
        apply_address_filter!(objects, filter_criterion)
      when :contact_info
        apply_contact_info_filter!(objects, filter_criterion)
      when :any
        # objects1 = apply_address_filter!(objects.deep_dup, filter_criterion)
        # objects2 = apply_contact_info_filter!(objects.deep_dup, filter_criterion)
        # allowed_attributes = %w(orgas.title orgas.short_description orgas.description events.title events.short_description events.description)
        # objects3 = search(filter_criterion, allowed_attributes, objects.deep_dup)
        # objects.where(id: (objects1.map(&:id) + objects2.map(&:id) + objects3.map(&:id)).uniq)
        # allowed_attributes =
        #   %w(locations.street locations.placename locations.city locations.district)

        # build allowed attributes
        allowed_attributes = %w(orgas.title orgas.short_description orgas.description events.title events.short_description events.description)
        allowed_attributes +=
          %w(contact_infos.mail contact_infos.phone
              contact_infos.contact_person contact_infos.web contact_infos.social_media)
        # join locations
        table_name = :locations
        association_name = :locatable
        objects =
          objects.joins(
            "LEFT JOIN #{table_name} ON " +
              "entry_id = #{table_name}.#{association_name}_id AND entry_type = #{table_name}.#{association_name}_type")
        # join contact_infos
        table_name = :contact_infos
        association_name = :contactable
        objects =
          objects.joins(
            "LEFT JOIN #{table_name} ON " +
              "entry_id = #{table_name}.#{association_name}_id AND entry_type = #{table_name}.#{association_name}_type")
        # do search
        objects = search(filter_criterion, allowed_attributes, objects)
        objects.distinct(:id)
      when :annotation_category_id
        objects.where(annotation_category_id: filter_criterion)
      else
        objects
      end
    objects
  end

  def apply_address_filter!(objects, filter_criterion)
    allowed_attributes =
      %w(locations.street locations.placename locations.city locations.district)
    apply_nested_objects_filter!(objects, filter_criterion, 'locations', 'locatable', allowed_attributes)
  end

  def apply_contact_info_filter!(objects, filter_criterion)
    allowed_attributes =
      %w(contact_infos.mail contact_infos.phone
          contact_infos.contact_person contact_infos.web contact_infos.social_media)
    apply_nested_objects_filter!(objects, filter_criterion, 'contact_infos', 'contactable', allowed_attributes)
  end

  def apply_nested_objects_filter!(objects, filter_criterion, table_name, association_name, allowed_attributes)
    objects =
      objects.joins(
        "LEFT JOIN #{table_name} ON " +
          "entry_id = #{table_name}.#{association_name}_id AND entry_type = #{table_name}.#{association_name}_type")
    objects = search(filter_criterion, allowed_attributes, objects)
    objects
  end

  def custom_search_query(filter, filter_criterion, objects)
    objects.
      where("orgas.#{filter} LIKE ? OR events.#{filter} LIKE ?",
        "%#{filter_criterion}%", "%#{filter_criterion}%")
  end

  def do_includes!(objects)
    objects.includes(:entry)
  end

end
