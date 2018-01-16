class OrgaType < ApplicationRecord
  # CLASS METHODS
  class << self
    def default_orga_type_id
      OrgaType.where(name: 'Organization').first['id']
    end
  end
end
