class Api::V1::EntriesController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Entry.with_entries
  end

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(area any address).freeze
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
      when :any
        raise 'We should no longer come here.'
      when :annotation_category_id
        objects.where(annotation_category_id: filter_criterion)
      else
        objects
      end
    objects
  end

  def apply_address_filter!(objects, filter_criterion)
    allowed_attributes =
      %w(addresses.street addresses.title addresses.city addresses.district)
    apply_nested_objects_filter!(objects, filter_criterion, 'addresses', 'owner', allowed_attributes)
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
