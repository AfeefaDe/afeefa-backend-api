FactoryGirl.define do

  factory :orga do
    title {"title#{rand(0..10000)}"}
    description 'this is a description of this orga'
    short_description 'this is the short description'
    area 'dresden'

    parent_orga { Orga.root_orga }

    locations { [build(:location)] }
    contacts { [build(:contact)] }
    association :category, factory: :category

    after(:build) do |orga|
      orga.orga_type_id = OrgaType.default_orga_type_id

      if orga.contacts.present?
        location = orga.locations.first
        location.owner = orga

        contact = orga.contacts.first
        contact.owner = orga
        contact.location = location
        location.contact = contact
      end
    end

    factory :orga_with_random_title do
      title {"title#{rand(0..10000)}"}
    end

    factory :orga_without_contacts do
      contacts []
      locations []
    end

    factory :another_orga do
      title 'another orga'
    end

    factory :orga_with_initiator do
      after(:create) do |orga|
        orga.project_initiators << create(:orga)
      end
    end

    factory :active_orga do
      title 'an active orga'
      state StateMachine::ACTIVE
    end

    factory :orga_with_admin do
      title 'orga with admin'
      users { build_list :user, 1 }

      after(:build) do |orga|
        role = Role.new(title: Role::ORGA_ADMIN, user: orga.users.first, orga: orga)
        orga.roles << role
        orga.users.first.roles << role
      end

      after(:create) do |orga|
        orga.roles.map(&:save!)
        orga.users.map(&:save!)
      end
    end
  end


end
