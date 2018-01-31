FactoryGirl.define do

  factory :location_old, class: Location do
    street 'Hauptstr. 1'

    factory :location_old_dresden do
      street 'Reißigerstr. 6'
      zip '01307'
      city 'Dresden'
      country 'Deutschland'
    end
  end

end
