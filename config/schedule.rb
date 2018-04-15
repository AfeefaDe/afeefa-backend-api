set :chronic_options, hours24: true

every 1.day, at: '03:01' do
  runner 'BackendToPhraseappSyncJob.perform_now'
end

every 1.day, at: '04:07' do
  runner 'PhraseappToBackendSyncJob.perform_now'
end

every 1.day, at: '05:12' do
  runner 'FacebookEventImportJob.perform_now'
end
