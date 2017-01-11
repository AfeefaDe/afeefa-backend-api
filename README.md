GETTING STARTED:

bundle install ( install ruby-dev zlib1g-dev liblzma-dev, mysql-client libmysqlclient-dev, libsqlite3-dev)

cp config/database.yml.example config/database.yml

vi config/database.yml
* configure dbname, user, password

```
RAILS_ENV=[test|development|production] (default=development)
rake db:create
rake db:migrate
rake db:seed
```

for usage of live db dump:
* create db connection for resource defined in database.yml under key 'afeefa'
* import the db dump under db/afeefa_neos_live.sql using mysql

rails s [-p]

# Changelog

* 04.01.2017
Max mysql connections increased to 5 in database.yml.example - workaround for error: `ERROR ActiveRecord::ConnectionTimeoutError: could not obtain a connection from the pool within 5.000 seconds`

# How to deploy

Run this command in your project folder:

```
bundle exec cap [dev|production] deploy
```