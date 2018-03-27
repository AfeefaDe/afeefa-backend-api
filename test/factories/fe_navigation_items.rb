FactoryGirl.define do

  factory :fe_navigation_item, class: DataModules::FENavigation::FENavigationItem do
    title {"title#{rand(0..1000)}"}
    association :navigation, factory: :fe_navigation

    factory :fe_navigation_item_with_sub_items do
      transient do
        sub_items_count 2
      end
      after(:create) do |navigation_item, evaluator|
        create_list(:fe_navigation_item, evaluator.sub_items_count, navigation: navigation_item.navigation, parent: navigation_item)
      end
    end
  end

end
