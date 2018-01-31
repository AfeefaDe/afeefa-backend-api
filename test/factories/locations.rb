FactoryGirl.define do

  factory :location, class: DataPlugins::Location::Location do
    street 'Hauptstr. 1'

    factory :location_dresden do
      street 'Reißigerstr. 6'
      zip '01307'
      city 'Dresden'

      factory :afeefa_office do
        title 'Afeefa Büro'
        street 'Bayrische Str.8'
        zip '01060'

        factory :impact_hub do
          title 'ImpactHub Dresden'
        end
      end

      factory :afeefa_montagscafe do
        title 'Afeefa im Montagscafé'
        street 'Glacisstraße 28'
        zip '01099'
      end
    end
  end

end
