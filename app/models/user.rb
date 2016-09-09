class User < ApplicationRecord
  include Owner

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :roles
  has_many :orgas, through: :roles

  has_many :created_events, class_name: 'Event', foreign_key: :creator_id

  # def can!(ability, subject, message)
  #   unless abilities.can? ability, subject
  #     raise CanCan::AccessDenied.new(message, caller_locations(1, 1)[0].label)
  #   end
  # end

  # def can?(ability, subject)
  #   abilities.can? ability, subject
  # end

  # def orga_member?(orga)
  #   has_role_for?(orga, Role::ORGA_MEMBER)
  # end

  # def orga_admin?(orga)
  #   has_role_for?(orga, Role::ORGA_ADMIN)
  # end

  # def create_user_and_add_to_orga(email:, forename:, surname:, orga:)
  #   can! :write_orga_structure, orga, 'You are not authorized to modify the user list of this organization!'
  #
  #   new_user = User.create!(email: email, forename: forename, surname: surname, password: 'abc12345')
  #   orga.add_new_member(new_member: new_user, admin: self)
  # end

  # def leave_orga(orga:)
  #   unless belongs_to_orga?(orga)
  #     raise ActiveRecord::RecordNotFound.new('user is not member of orga')
  #   end
  #   roles.where(orga: orga, user: self).delete_all
  # end

  # def remove_user_from_orga(member:, orga:)
  #   can! :write_orga_structure, orga, 'You are not authorized to modify the user list of this organization!'
  #   member.leave_orga(orga: orga)
  # end

  # def promote_member_to_admin(member:, orga:)
  #   update_role_for_member member: member, orga: orga, role: Role::ORGA_ADMIN
  # end

  # def demote_admin_to_member(member:, orga:)
  #   update_role_for_member member: member, orga: orga, role: Role::ORGA_MEMBER
  # end

  class << self
    # def current
    #   @user
    # end

    # def current=(user)
    #   @user = user
    # end
  end

  # def belongs_to_orga?(orga)
  #   orgas.pluck(:id).include?(orga.id)
  # end

  private

  # def abilities
  #   @ability ||= Ability.new(self)
  # end

  # def has_role_for?(orga, role)
  #   if belongs_to_orga?(orga)
  #     roles.where(orga_id: orga.id).first.try(:title) == role
  #   else
  #     false
  #   end
  # end

  # def update_role_for_member(member:, orga:, role:)
  #   can! :write_orga_structure, orga, 'You are not authorized to modify the user list of this organization!'
  #   current_role = Role.find_by(orga: orga, user: member)
  #   if current_role.nil?
  #     raise ActiveRecord::RecordNotFound.new('user not in orga!')
  #   end
  #   current_role.update(title: role)
  # end

end
