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

## Running the Api

`rails s` or `rails s -b 10.0.3.130` or `rails s -b 10.0.3.130 -p 3001`

## Remote Debugging

On server and client both install:

* `gem install ruby-debug-ide`
* `gem install debase`

Then start the remote server like this:

`rdebug-ide --port 1235 --dispatcher-port 26166 --host 0.0.0.0 -- bin/rails s -b 10.0.3.130`

Attach your local IDE debugger. VSCode example config:

```
    {
      "name": "Listen for rdebug-ide",
      "type": "Ruby",
      "request": "attach",
      "cwd": "${workspaceRoot}",
      "remoteHost": "backend.afeefa.dev",
      "remotePort": "1236",
      "remoteWorkspaceRoot": "/afeefa/fapi"
    }
```