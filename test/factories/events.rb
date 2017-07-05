FactoryGirl.define do

  factory :event do
      title 'an event'
      description 'description of an event'
      short_description 'short description'
      area 'dresden'
      date_start { I18n.l(Date.tomorrow) }
      creator { User.first }
      association :orga, factory: :orga
      association :category, factory: :category
      contact_infos { [build(:contact_info)] }
      locations { [build(:location)] }

      after(:build) do |event|
        event.contact_infos.each do |ci|
          ci.contactable = event
        end
        event.locations.each do |l|
          l.locatable = event
        end
      end

      factory :another_event do
        title 'another event'
      end

      factory :active_event do
        title 'an active event'
        state StateMachine::ACTIVE
      end
  end

end
