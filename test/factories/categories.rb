FactoryBot.define do

  factory :category, class: Category do
    title { 'leisure' }

    factory :sub_category do
      title { 'soccer' }
      parent_id { create(:category).id }
    end
  end

end
