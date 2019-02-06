require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  test 'create contact does not triggers fapi cache' do
    orga = create(:orga)

    FapiCacheJob.any_instance.expects(:update_entry).with(orga).never

    DataPlugins::Contact::Contact.new(owner: orga).save(validate: false)
  end

  test 'update contact triggers fapi cache' do
    orga = create(:orga)
    contact = DataPlugins::Contact::Contact.create!(owner: orga, location: nil, title: 'old title')
    orga.update!(linked_contact: contact)
    contact.reload

    FapiCacheJob.any_instance.expects(:update_entry).with(orga)

    contact.update!(title: 'new title')
  end

  test 'remove contact triggers fapi cache' do
    orga = create(:orga)
    contact = DataPlugins::Contact::Contact.create!(owner: orga, location: nil, title: 'title')
    orga.update!(linked_contact: contact)
    contact.reload

    FapiCacheJob.any_instance.expects(:update_entry).with(orga)

    contact.destroy!
  end
end
