class AreaChapterConfig < ApplicationRecord

  belongs_to :chapter_config

  scope :by_area, ->(area) { where(area: area) }
  scope :active, ->() { joins(:chapter_config).references(:chapter_config).where(chapter_configs: { active: true }) }
end
