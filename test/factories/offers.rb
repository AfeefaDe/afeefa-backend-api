FactoryBot.define do

  factory :offer, class: DataModules::Offer::Offer do
    title { 'offer generated by factory' }
    short_description { 'this is an offer short description' }
    area { 'dresden' }

    transient do
      actors { [] }
    end

    after(:create) do |offer, evaluator|
      evaluator.actors.each do |actor_id|
        offer.link_owner(actor_id)
      end
    end

  end
end
