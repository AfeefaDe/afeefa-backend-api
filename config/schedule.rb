set :chronic_options, hours24: true

# if we need maintenance task run:
# every 1.day, at: '00:01' do
#   runner 'TranslationSyncJob.perform_now'
# end

every 1.day, at: '03:01' do
  runner 'TranslationCacheJob.perform_now'
end
