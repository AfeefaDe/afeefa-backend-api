FactoryGirl.define do
  factory :user do
    email {"foo#{rand(0..1000)}@afeefa.de"}
    forename 'Max'
    surname 'Mustermann'
    # TODO: remove required password from device
    password 'abc12346'

    factory :another_user do
      email 'bar@afeefa.de'
    end

    # factory :admin do
    #
    #   email 'admin@afeefa.de'
    #
    #   after(:build) do |user|
    #     #todo: make easier... if possible
    #     user.roles << Role.new(title: Role::ORGA_ADMIN, orga: build(:orga), user: user)
    #   end
    # end
    #
    # factory :member do
    #
    #   email 'member@afeefa.de'
    #
    #   transient do
    #     orga {build(:orga)}
    #   end
    #
    #   after(:build) do |member, evaluator|
    #     member.roles << Role.new(title: Role::ORGA_MEMBER, orga: evaluator.orga, user: member)
    #   end
    # end

    # after(:create) do |user|
    #   user.orgas.map(&:save!)
    # end

  end
end
