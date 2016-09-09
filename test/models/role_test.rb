require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  # setup do
  #   @role = Role.new
  #   @role.title = Role::ORGA_ADMIN
  # end

  # test 'role should have valid title' do
  #   @role.title = nil
  #
  #   assert !@role.valid?
  #   assert @role.errors[:title].any?
  #
  #   @role.title = Role::ORGA_ADMIN
  #   @role.valid?
  #   assert @role.errors[:title].blank?, @role.errors.full_messages
  # end

  # test 'role should have user and orga' do
  #   user = User.new
  #   user.roles << @role
  #   assert !@role.save
  #
  #   orga = Orga.first
  #   orga.roles << @role
  #   assert @role.save, @role.errors.full_messages
  # end
end
