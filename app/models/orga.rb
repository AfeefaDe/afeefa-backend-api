class Orga < ApplicationRecord
  include Owner

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_orgas, :children
  alias_method :sub_orgas=, :children=
  alias_method :parent_orga, :parent
  alias_method :parent_orga=, :parent=

  has_many :roles, dependent: :destroy
  has_many :users, through: :roles
  has_many :admins, -> { where(roles: { title: Role::ORGA_ADMIN }) }, through: :roles, source: :user
  has_many :locations, as: :locatable

  has_and_belongs_to_many :categories, join_table: 'orga_category_relations'

  validates :title, presence: true, length: { minimum: 5 }
  # TODO: maybe refactor and write own UniquenessValidator
  validates_uniqueness_of :title
  validates_presence_of :parent_id

  before_destroy :move_sub_orgas_to_parent, prepend: true

  def move_sub_orgas_to_parent
    sub_orgas.each do |suborga|
      suborga.parent_orga = parent_orga
      suborga.save!
    end
    self.reload
  end

  # def add_new_member(new_member:, admin:)
  #   admin.can! :write_orga_structure, self, 'You are not authorized to modify the user list of this organization!'
  #   if new_member.belongs_to_orga?(self)
  #     raise UserIsAlreadyMemberException
  #   else
  #     Role.create!(user: new_member, orga: self, title: Role::ORGA_MEMBER)
  #     return new_member
  #   end
  # end

  # def list_members(member:)
  #   member.can! :read_orga, self, 'You are not authorized to access the data of this organization!'
  #   users
  # end

  # def update_data(member:, data:)
  #   member.can! :write_orga_data, self, 'You are not authorized to modify the data of this organization!'
  #   self.update(data)
  # end

  # def change_active_state(admin:, active:)
  #   admin.can! :write_orga_structure, self, 'You are not authorized to modify the state of this organization!'
  #   self.update(active: active)
  # end
end
