class Role < ApplicationRecord
  belongs_to :user
  belongs_to :orga

  ORGA_ADMIN = 'orga_admin'
  ORGA_MEMBER = 'orga_user'
  ROLES = [ORGA_ADMIN, ORGA_MEMBER]

  # validates_inclusion_of :title, within: ROLES
  # validates_presence_of :user, :orga
end
