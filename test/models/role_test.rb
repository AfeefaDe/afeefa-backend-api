require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  setup do
    @role = Role.new
    @role.title = Role::ORGA_ADMIN
  end

  test 'role should have valid title' do
    @role.title = nil

    assert !@role.valid?
    assert @role.errors[:title].any?

    @role.title = Role::ORGA_ADMIN
    @role.valid?
    assert @role.errors[:title].blank?, @role.errors.full_messages
  end

  test 'role should have user and orga' do
    assert !@role.valid?

    user = create(:user)
    user.roles << @role
    assert !@role.valid?

    orga = create(:orga)
    orga.roles << @role
    assert @role.valid?, @role.errors.full_messages
  end
end
