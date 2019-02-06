FactoryBot.define do

  factory :resource_item do
    title { 'resource' }
    description { 'this is a description of this resource' }

    orga { build(:orga) }

    factory :another_resource_item do
      title { 'another resource' }
    end
  end

end
