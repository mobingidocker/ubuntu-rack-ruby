#!/bin/bash

source /etc/profile.d/rbenv.sh

echo "installing" > /var/log/container_status

echo "Ruby Rehash"
rbenv rehash

echo "Ruby Version:"
ruby -v

echo "Running init script"
bash /tmp/init/init.sh

echo "Create Rails Directory"
mkdir -p /srv/rails
cp -r /srv/code /srv/rails/app
chown -R www-data:www-data /srv/rails/app/public
cd /srv/rails/app
mkdir -p tmp
chown -R www-data:www-data /srv/rails/app/tmp
chmod -R 777 /srv/rails/app/tmp

echo "Prepare logging directory"
rm -rf /srv/rails/app/log
mkdir -p /var/log/rails
ln -s /var/log/rails/ /srv/rails/app/log

echo "Prepare production log"
touch log/production.log
chmod 666 log/production.log
chown -R www-data:www-data /srv/rails/app/log/

echo "Running bundler..."
bundle install 2>&1 | tee /var/log/bundler.log

echo "Migrate database"
bundle exec rake db:create 2>&1 | tee /var/log/migration.log
bundle exec rake db:migrate 2>&1 | tee /var/log/migration.log
bundle exec rake db:seed 2>&1 | tee /var/log/migration.log
bundle exec rake assets:precompile 2>&1 | tee /var/log/migration.log

echo "complete" > /var/log/container_status

/usr/bin/supervisord
