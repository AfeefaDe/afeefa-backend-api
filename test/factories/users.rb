FactoryBot.define do
  factory :user do
    email { "foo#{rand(0..1000)}@afeefa.de" }
    forename { 'Max' }
    surname { 'Mustermann' }
    # TODO: Think about removeing required password from device...
    password { 'abc12346' }
    available_areas { ['dresden'] }
    area { 'dresden' }

    factory :another_user do
      email { 'bar@afeefa.de' }
    end
  end
end
