class CreateFapiCacheJobs < ActiveRecord::Migration[5.0]
  def up
    unless ActiveRecord::Base.connection.table_exists? 'fapi_cache_jobs'
      create_table :fapi_cache_jobs do |t|
        t.references :entry, polymorphic: true, index: true
        t.references :area, index: true
        t.boolean :updated
        t.boolean :deleted
        t.boolean :translated
        t.string :language

        t.datetime :created_at
        t.datetime :started_at
        t.datetime :finished_at
      end
    end
  end

  def down
    drop_table :fapi_cache_jobs
  end
end
