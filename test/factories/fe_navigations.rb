FactoryGirl.define do

  factory :fe_navigation, class: DataModules::FENavigation::FENavigation do
    area 'dresden'

    factory :fe_navigation_with_items, class: DataModules::FENavigation::FENavigation do
      transient do
        entry_count 2
      end
      after(:create) do |navigation, evaluator|
        create_list(:fe_navigation_item, evaluator.entry_count, navigation: navigation)
      end
    end

    factory :fe_navigation_with_items_and_sub_items do
      transient do
        items_count 2
        sub_items_count 2
      end

      after(:create) do |navigation, evaluator|
        create_list(:fe_navigation_item_with_sub_items, evaluator.items_count, navigation: navigation, sub_items_count: evaluator.sub_items_count)
      end
    end
  end

end
