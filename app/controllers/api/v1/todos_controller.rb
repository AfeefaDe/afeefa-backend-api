class Api::V1::TodosController < Api::V1::EntriesBaseController

  private

  def base_for_find_objects
    Todo.with_annotation.with_entries
  end

  def find_objects
    @objects =
      base_for_find_objects ||
        self.class.name.to_s.split('::').last.gsub('Controller', '').singularize.constantize.all

    if (filter = filter_params) && filter.respond_to?(:keys) && filter.keys.present?
      filter_params.each do |attribute, filter_criterion|
        if attribute.to_s.in?(filter_whitelist)
          @objects =
            @objects.where("orgas.#{attribute} LIKE ? OR events.#{attribute} LIKE ?",
              "%#{filter_criterion}%", "%#{filter_criterion}%")
        elsif attribute.to_s.in?(custom_filter_whitelist)
          @objects = apply_custom_filter!(attribute, @objects)
        end
      end
    end

    @objects =
      @objects.includes(:entry).group(:entry_id, :entry_type)
  end

end
