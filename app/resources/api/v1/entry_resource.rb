class Api::V1::EntryResource < Api::V1::BaseResource

  immutable
  abstract

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :category

  has_many :annotations
  has_many :locations
  has_many :contact_infos

  class << self
    def find(filters, options = {})
      # check for 'todo' filter and add sort constraints
      if filters.key?('todo')
        options[:sort_criteria] ||= []
        options[:sort_criteria] << [
          {
            field: 'annotation.updated_at', direction: :asc
          }
        ]
      end

      orgas = Api::V1::OrgaResource.find(filters, options)
      events = Api::V1::EventResource.find(filters, options)
      sort(orgas + events, options[:sort_criteria])
    end

    def find_count(filters, options = {})
      orgas = Api::V1::OrgaResource.find_count(filters, options)
      events = Api::V1::EventResource.find_count(filters, options)

      (orgas + events).size
    end

    private

    def sort(records, criteria)
      return records if criteria.blank?

      records.sort do |record1, record2|
        sortings =
          criteria.map do |criterium|
            if criterium[:direction] == :desc
              record2.send(criterium[:field]) <=> record1.send(criterium[:field])
            else
              record1.send(criterium[:field]) <=> record2.send(criterium[:field])
            end
          end
        sortings.delete(0)
        sortings.first
      end
    end
  end

  filter :todo
  filter :title
  filter :description

end
