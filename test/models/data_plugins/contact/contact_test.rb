require 'test_helper'

class ContactTest < ActiveSupport::TestCase

  should 'create contact triggers fapi cache' do
    orga = create(:orga)

    FapiClient.any_instance.expects(:entry_updated).with(orga)

    DataPlugins::Contact::Contact.new(owner: orga).save(validate: false)
  end

  should 'update contact triggers fapi cache' do
    orga = create(:orga)
    contact = DataPlugins::Contact::Contact.create!(owner: orga, location: nil, title: 'old title')

    FapiClient.any_instance.expects(:entry_updated).with(orga)

    contact.update(title: 'new title')
  end

  should 'remove contact triggers fapi cache' do
    orga = create(:orga)
    contact = DataPlugins::Contact::Contact.create!(owner: orga, location: nil, title: 'title')

    FapiClient.any_instance.expects(:entry_updated).with(orga)

    contact.destroy
  end

end
