module DataPlugins::Location::Concerns::HasLocations

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :locations, class_name: ::DataPlugins::Location::Location, as: :owner
  end

  module ClassMethods
    def location_params
      [:title, :street, :zip, :city, :lat, :lon, :directions]
    end
  end

end
