FactoryGirl.define do

  factory :resource do
    title 'resource'
    description 'this is a description of this resource'

    orga { build(:orga) }

    factory :another_resource do
      title 'another resource'
    end
  end

end
