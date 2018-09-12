FactoryGirl.define do
  factory :fe_navigation_item, class: DataModules::FeNavigation::FeNavigationItem do
    title { "title#{rand(0..1000)}" }
    association :navigation, factory: :fe_navigation

    after(:create) do |navigation_item, _evaluator|
      navigation_item.update_attribute(:order, navigation_item.id)
    end

    factory :fe_navigation_item_with_sub_items do
      transient do
        sub_items_count 2
      end

      after(:create) do |navigation_item, evaluator|
        create_list(
          :fe_navigation_item,
          evaluator.sub_items_count,
          navigation: navigation_item.navigation,
          parent: navigation_item
        )
      end
    end
  end
end
