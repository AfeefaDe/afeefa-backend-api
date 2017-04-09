FactoryGirl.define do

  factory :location do
    street 'Hauptstr. 1'

    factory :location_dresden do
      street 'Reißigerstr. 6'
      zip '01307'
      city 'Dresden'
      country 'Deutschland'
    end
  end

end
