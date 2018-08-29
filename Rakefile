# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

task :disable_apis do
  Settings.phraseapp.active = false
  Settings.afeefa.fapi_sync_active = false
  puts "#### Disable Phraseapp and Fapi sync before Migrating ##### PA.active: #{Settings.phraseapp.active}, Fapi.active: #{Settings.afeefa.fapi_sync_active}"
end

Rake::Task["db:migrate"].enhance [:disable_apis]
