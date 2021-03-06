require 'csv'

module Import
  module Csv

    class << self
      def logger
        @logger ||=
          if log_file = Settings.phraseapp.log_file
            Logger.new(log_file)
          else
            Rails.logger
          end
      end

      def import(file:, area:, limit: nil, headers: true, handle_title_duplicates: true)
        imported = 0
        errors = []
        limit = limit.try(:to_i)
        csv_text = File.read(file)
        csv = CSV.parse(csv_text, headers: headers)
        csv.each_with_index do |row, index|
          begin
            attributes = row.to_hash.deep_symbolize_keys
            attributes[:category] = Category.main_categories.find_by(title: attributes[:category])
            attributes[:sub_category] = Category.sub_categories.find_by(title: attributes[:sub_category])
            orga_attributes =
              attributes.slice(*%i(title description category sub_category))

            orga = Orga.new(orga_attributes.merge(state: 'active', area: area))
            orga.skip_short_description_validation!

            if handle_title_duplicates
              orga = handle_title_duplicates(orga)
            end

            orga.save!

            # ContactInfo was removed, migrate this to Contact!
            # contact_info_attributes =
            #   attributes.slice(*%i(mail phone fax contact_person web social_media spoken_languages opening_hours))
            # contact_info = ContactInfo.new(contact_info_attributes.merge(contactable: orga))
            # contact_info.save!

            location_attributes =
              attributes.slice(*%i(title street zip city lat lon))
            location = DataPlugins::Location::Location.new(location_attributes.merge(owner: orga))
            location.save!

            imported = imported + 1
          rescue => exception
            message = "Error while importing file, during the following entry:\n\n"
            message << "#{orga.attributes.inspect}\n"
            message << "#{orga.errors.messages.inspect}\n"
            message << "#{exception.message} for #{orga.title}\n"
            message << "#{exception.backtrace[0..14].join("\n")}\n\n"
            errors << message
          end
          break if limit && limit > 0 && index >= limit - 1
        end

        if errors.count > 0
          errors << "overall errors: #{errors.count}\n"
        end

        errors.each do |error|
          logger.error error
          raise error if Rails.env.development?
        end

        imported
      end

      private

      def handle_title_duplicates(orga, max_number: 100)
        original_title = orga.title
        title_suffix = 2

        while orga.invalid? &&
            (title_validation_error = orga.errors[:title].first) &&
            (title_validation_error =~ /bereits vergeben/) &&
            (title_suffix < max_number)
          orga.title = "#{original_title}##{title_suffix}"
          title_suffix = title_suffix + 1
        end
        orga
      end
    end

  end
end
