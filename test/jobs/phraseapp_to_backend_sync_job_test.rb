require 'test_helper'

class PhraseappToBackendSyncJobTest < ActiveSupport::TestCase

  test 'run the job like donald trump' do
    PhraseAppClient.any_instance.expects(:get_all_translations).with(Translatable::TRANSLATABLE_LOCALES).returns([1, 2, 3])
    TranslationCache.expects(:rebuild_db_cache!).with([1, 2, 3])
    FapiCacheJob.any_instance.expects(:update_all).with()

    PhraseappToBackendSyncJob.perform_now
  end

end