module Entry
  extend ActiveSupport::Concern

  include Thing

  included do
    has_many :locations, as: :locatable
  end

end
