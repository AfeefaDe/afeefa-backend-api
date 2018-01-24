module DataPlugins::Location::Concerns::HasLocations

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :locations, class_name: ::DataPlugins::Location::Location, foreign_key: :owner_id
  end

end
