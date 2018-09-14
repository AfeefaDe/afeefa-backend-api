module FapiCacheable
  extend ActiveSupport::Concern
  included do
    after_commit on: [:create, :update] do
      fapi_cacheable_on_save
    end

    after_destroy do
      fapi_cacheable_on_destroy
    end
  end

  def fapi_cacheable_on_save
    # override if necessary
    FapiCacheJob.update_entry(self)
  end

  def fapi_cacheable_on_destroy
    # override if necessary
    FapiCacheJob.delete_entry(self)
  end

end
