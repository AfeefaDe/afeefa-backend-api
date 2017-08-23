require 'csv'

module Import
  module Csv

    class << self
      def import(file:, area:, limit: nil, headers: true)
        imported = 0
        limit = limit.try(:to_i)
        csv_text = File.read(file)
        csv = CSV.parse(csv_text, headers: headers)
        csv.each_with_index do |row, index|
          begin
            attributes = row.to_hash.deep_symbolize_keys
            attributes[:category] = Category.main_categories.find_by(title: attributes[:category])
            attributes[:sub_category] = Category.sub_categories.find_by(title: attributes[:category])
            orga_attributes =
              attributes.slice(*%i(title description category sub_category))

            orga = Orga.new(orga_attributes.merge(active: true, area: area))
            orga.skip_short_description_validation!
            orga.save!

            contact_info_attributes =
              attributes.slice(*%i(mail phone fax contact_person web social_media spoken_languages opening_hours))
            contact_info = ContactInfo.new(contact_info_attributes.merge(contactable: orga))
            contact_info.save!

            location_attributes =
              attributes.slice(*%i(placename street zip city lat lon))
            location = Location.new(location_attributes.merge(locatable: orga))
            location.save!

            imported = index + 1
            break if limit && limit > 0 && index >= limit - 1
          rescue => exception
            puts 'Error while importing file, during the following entry:'
            puts orga.attributes.inspect
            puts orga.errors.messages.inspect
            puts exception.message
            puts exception.backtrace.join("\n")
          end
        end
        imported
      end
    end

  end
end
