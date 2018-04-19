FactoryGirl.define do

  factory :event do
    title 'an event'
    description 'description of an event'
    short_description 'short description'
    area 'dresden'
    date_start { I18n.l(Date.tomorrow) }
    creator { User.first }
    # association :orga, factory: :orga_with_random_title
    association :category, factory: :category

    locations { [build(:location)] }

    transient do
      host false
    end

    after(:build) do |event, evaluator|
      if evaluator.host
        EventHost.create(actor: evaluator.host, event: event)
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
