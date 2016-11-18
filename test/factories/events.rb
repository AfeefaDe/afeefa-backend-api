FactoryGirl.define do

  factory :event do
      title 'an event'
      description 'description of an event'
      creator { User.first }
      association :orga, factory: :orga
      category { Able::CATEGORIES.first }

      # handle contact_infos
      transient do
        contact_infos { [build(:contact_info)] }
      end

      after(:build) do |event, evaluator|
        evaluator.contact_infos.each do |contact_info|
          contact_info.contactable = event
        end
      end

      after(:create) do |event|
        event.contact_infos.map(&:save!)
      end
      # handle contact_infos end

      factory :another_event do
        title 'another event'
      end

      factory :active_event do
        title 'an active event'
        state StateMachine::ACTIVE
      end
  end

end
