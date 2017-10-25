namespace :dev do

  desc 'creates dummy resources and orgas if needed'
  task create_resources: :environment do
    Resource.create_dummy_data
  end

end
