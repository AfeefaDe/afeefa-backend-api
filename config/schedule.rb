set :chronic_options, hours24: true

every 1.day, :at => '00:01' do
  runner 'TranslationCacheJob.perform_now'
end