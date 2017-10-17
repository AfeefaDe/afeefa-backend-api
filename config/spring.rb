%w(
  .ruby-version
  .rbenv-vars
  config/settings.yml
  config/settings.local.yml
  config/settings/test.yml
  config/settings/development.yml
  config/settings/production.yml
  tmp/restart.txt
  tmp/caching-dev.txt
).each { |path| Spring.watch(path) }
