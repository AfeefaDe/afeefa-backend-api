FactoryGirl.define do

  factory :orga do
    title 'an orga'
    description 'this is a short description of this orga'

    parent_orga { Orga.root_orga }

    contact_infos { [build(:contact_info)] }
    locations { [build(:location)] }
    association :category, factory: :category
    association :sub_category, factory: :sub_category

    after(:build) do |orga|
      orga.contact_infos.each do |ci|
        ci.contactable = orga
      end
      orga.locations.each do |l|
        l.locatable = orga
      end
    end

    factory :another_orga do
      title 'another orga'
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
