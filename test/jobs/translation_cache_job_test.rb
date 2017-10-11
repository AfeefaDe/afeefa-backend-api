require 'test_helper'

class TranslationCacheJobTest < ActiveSupport::TestCase

  should 'run the job like donald trump' do
    PhraseAppClient.any_instance.expects(:get_all_translations).with(Translatable::TRANSLATABLE_LOCALES).returns([1, 2, 3])
    TranslationCache.expects(:rebuild_db_cache!).with([1, 2, 3])
    FapiClient.any_instance.expects(:all_updated).with()

    TranslationCacheJob.perform_now
  end

end