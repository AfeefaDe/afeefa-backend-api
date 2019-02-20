#!/bin/bash

unset BUNDLE_PATH
unset BUNDLE_BIN

rm /usr/src/app/tmp/pids/server.pid

gem install bundler
bundle install --path 'vendor/bundle'
bundle exec rails db:migrate
bundle exec rails s -b 0.0.0.0 -p 3000