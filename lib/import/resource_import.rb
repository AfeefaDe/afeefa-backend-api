require 'csv'

module Import
  module ResourceImport

    class << self
      def import(resource_file:)
        imported = 0
        errors = []

        resource_csv_file = File.read(resource_file)
        resource_csv = CSV.parse(resource_csv_file, headers: true)
        resource_csv.each_with_index do |row|
          begin

            attributes = row.to_hash.deep_symbolize_keys

            resource = ResourceItem.new(title: attributes[:title], description: attributes[:description], tags: attributes[:tag])
            resource.orga = Orga.find_by(title: attributes[:orga])
            resource.save!


            errors << "ID: #{resource.id} – Could not find orga with title '#{attributes[:orga]}'!" if resource.orga_id.blank?

            imported = imported + 1
          rescue => exception
            message = "Error while importing, during resource entry TITLE #{resource.title}:\n\n"
            message << "#{exception.message}\n"
            errors << message
          end
        end

        if errors.count > 0
          errors << "overall errors: #{errors.count}\n"
        end

        errors.each do |error|
          pp error
        end

        imported
      end
    end
  end
end
