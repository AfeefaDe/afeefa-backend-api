FactoryGirl.define do

  factory :category do
    title 'leisure'

    factory :sub_category do
      title 'soccer'
      parent_id { create(:category).id }
    end
  end

end
