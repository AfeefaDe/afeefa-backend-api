# uberspace service script for production (/home/afeefa/service/api/run):

#!/bin/sh

# These environment variables are sometimes needed by the running daemons
export USER=afeefa
export HOME=/home/afeefa

# Include the user-specific profile
source $HOME/.bash_profile

# Now let's go!
cd /home/afeefa/rails/afeefa-backend-api/current
exec /package/host/localhost/ruby-2.3.1/bin/bundle exec unicorn_rails --port 63259 2>&1
# exec /package/host/localhost/ruby-2.3.1/bin/bundle exec RAILS_ENV=production rails s --port 63259 2>&1

========================================================================================================

# uberspace service script for dev (/home/afeefa/service/dev-api/run):

#!/bin/sh

# These environment variables are sometimes needed by the running daemons
export USER=afeefa
export HOME=/home/afeefa

# Include the user-specific profile
source $HOME/.bash_profile

# Now let's go!
cd /home/afeefa/rails/afeefa-backend-api-dev/current
exec /package/host/localhost/ruby-2.3.1/bin/bundle exec unicorn_rails --port 65413 2>&1