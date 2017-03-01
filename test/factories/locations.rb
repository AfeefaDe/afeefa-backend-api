FactoryGirl.define do

  factory :location do
    street 'Hauptstr.'
    number '1'

    factory :location_dresden do
      street 'Geisingstr. 31'
      zip '01309'
      city 'Dresden'
      country 'Deutschland'
    end
  end

end
