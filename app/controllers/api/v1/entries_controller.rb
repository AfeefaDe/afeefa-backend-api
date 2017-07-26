class Api::V1::EntriesController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Entry.with_entries
  end

  def filter_whitelist
    %w(title description short_description).freeze
  end

  def custom_filter_whitelist
    %w(area).freeze
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
          tmp =
            objects.joins(
              'LEFT JOIN locations ON ' +
                'entry_id = locations.locatable_id AND entry_type = locations.locatable_type')
          search_string =
            %w(street placename city district).map do |attribute|
              "orgas.#{attribute} LIKE ? OR events.#{attribute} LIKE ?"
            end.join(' OR ')
          tmp.
            where(search_string,
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%")
        when :contact_info
          tmp =
            objects.joins(
              'LEFT JOIN contact_infos ON ' +
                'entry_id = contact_infos.contactable_id AND entry_type = contact_infos.contactable_type')
          search_string =
            %w(street placename city district).map do |attribute|
              "orgas.#{attribute} LIKE ? OR events.#{attribute} LIKE ?"
            end.join(' OR ')
          tmp.
            where(search_string,
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%",
              "%#{filter_criterion}%", "%#{filter_criterion}%")
        when :any
          tmp = objects
          %w(title short_description address contact_info).each do |sub_filter|
            tmp =
              if sub_filter.in?(filter_whitelist)
                apply_filter!(sub_filter, filter_criterion, tmp)
              else
                apply_custom_filter!(sub_filter, filter_criterion, tmp)
              end
          end
          tmp
        else
          objects
      end
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
