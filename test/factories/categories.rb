FactoryGirl.define do

  factory :category do
    title 'leisure'
    is_sub_category false

    factory :sub_category do
      title 'soccer'
      is_sub_category true
    end
  end

end
