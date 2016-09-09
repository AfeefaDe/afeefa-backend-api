require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  context 'with new orga' do
    setup do
      @my_orga = Orga.new
    end

    should 'orga attributes' do
      nil_defaults = [:title, :description]
      (nil_defaults).each do |attr|
        assert @my_orga.respond_to?(attr), "orga does not respond to #{attr}"
      end
      nil_defaults.each do |attr|
        assert_equal nil, @my_orga.send(attr)
      end
    end

    # should 'save orga' do
    #   assert_no_difference 'Orga.count' do
    #     assert !@my_orga.save
    #   end
    #
    #   @my_orga.title = '12345'
    #   assert_difference 'Orga.count' do
    #     assert @my_orga.save
    #   end
    # end

    # should 'orga title length' do
    #   @my_orga.title = '123'
    #   assert !@my_orga.valid?
    #
    #   @my_orga = build(:orga)
    #   assert @my_orga.valid?
    # end
  end

  should 'have contact_informations' do
    orga = create(:orga)
    assert orga.contact_infos.blank?
    assert contact_info = ContactInfo.create(contactable: orga)
    assert_includes orga.reload.contact_infos, contact_info
  end

  should 'have categories' do
    orga = create(:orga)
    assert orga.categories.blank?
    assert category = Category.new(title: 'irgendeine komische Kategorie')
    category.orgas << orga
    assert category.save
    assert_includes orga.reload.categories, category
  end

  # context 'As admin' do
  #   setup do
  #     @admin = create(:admin)
  #     @user = create(:user)
  #   end
  #
  #   should 'I want to add a new member to my orga' do
  #     orga = @admin.orgas.first
  #
  #     assert_difference('orga.users.count') do
  #       orga.add_new_member(new_member: @user, admin: @admin)
  #     end
  #
  #     assert_equal(orga, @user.reload.orgas.first)
  #   end
  #
  #   should 'I must not add a new member to a foreign orga' do
  #     orga = create(:another_orga)
  #
  #     assert_no_difference('@user.orgas.count') do
  #       assert_no_difference('orga.users.count') do
  #         assert_raise CanCan::AccessDenied do
  #           orga.add_new_member(new_member: @user, admin: @admin)
  #         end
  #       end
  #     end
  #   end
  #
  #   should 'I must not add the same member to my orga again' do
  #     orga = @admin.orgas.first
  #
  #     orga.add_new_member(new_member: @user, admin: @admin)
  #
  #     assert_no_difference('orga.users.count') do
  #       assert_no_difference('@user.orgas.count') do
  #         assert_raise UserIsAlreadyMemberException do
  #           orga.add_new_member(new_member: @user, admin: @admin)
  #         end
  #       end
  #     end
  #
  #     assert_no_difference('orga.users.count') do
  #       assert_no_difference('@user.orgas.count') do
  #         assert_raise UserIsAlreadyMemberException do
  #           orga.add_new_member(new_member: @admin, admin: @admin)
  #         end
  #       end
  #     end
  #   end
  #
  #   should 'have associated orgas' do
  #     orga = @admin.orgas.first
  #     another_orga = create(:another_orga)
  #
  #     assert_empty orga.sub_orgas
  #     assert_empty another_orga.sub_orgas
  #
  #     orga.sub_orgas << another_orga
  #     orga.reload.sub_orgas
  #     assert_includes orga.reload.sub_orgas, another_orga
  #     assert_equal orga, another_orga.reload.parent_orga
  #   end
  #
  #   should 'I want to delete a parent_orga without deleting sub_orgas' do
  #     parent_orga = @admin.orgas.first
  #     middle_orga = create(:orga_with_admin, parent_orga: parent_orga)
  #     last_orga = create(:another_orga, parent_orga: middle_orga)
  #
  #     assert_includes(parent_orga.sub_orgas, middle_orga)
  #     assert_includes(middle_orga.sub_orgas, last_orga)
  #
  #     middle_orga.destroy
  #     assert_equal parent_orga.id, last_orga.reload.parent_id
  #
  #     assert_includes(parent_orga.reload.sub_orgas, last_orga)
  #     assert middle_orga.destroyed?
  #   end
  # end

  # context 'As member' do
  #   setup do
  #     @member = create(:member)
  #   end
  #
  #   should 'I must not create a new suborga for an orga I am (only) a member in' do
  #     orga = @member.orgas.first
  #
  #     assert_no_difference('orga.sub_orgas.count') do
  #       assert_raise CanCan::AccessDenied do
  #         orga.create_suborga(admin: @member,
  #                             params: { :title => 'super-awesome orga',
  #                                       :description => 'this orga is magnificent' })
  #       end
  #     end
  #   end
  # end

  # context 'As user' do
  #   setup do
  #     @user = create(:user)
  #   end
  #
  #   should 'I must not create a new suborga for an orga I am not a member in' do
  #     orga = create(:orga)
  #
  #     assert_no_difference('orga.sub_orgas.count') do
  #       assert_raise CanCan::AccessDenied do
  #         orga.create_suborga(admin: @user,
  #                             params: { :title => 'super-awesome orga',
  #                                       :description => 'this orga is magnificent' })
  #       end
  #     end
  #   end
  # end
end
