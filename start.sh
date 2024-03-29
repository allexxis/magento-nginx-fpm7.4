#!/bin/bash

#Starting cron service
echo "Starting cron service ..."
service cron start

#Configure nginx domain and create credentials
echo "Configuring domain:${MAGENTO_DOMAIN} ..."
node replace.js

#Create Credentials
#echo "{\"http-basic\":{\"repo.magento.com\":{\"username\":\"${MAGENTO_USERNAME}\",\"password\":\"${MAGENTO_PASSWORD}\"}}}" > auth.json

#Install magento packages
echo "Installing packages ..."
composer install --no-interaction

#Give magento execution permission
chmod +x bin/magento

#Compile resources
echo "Setting production mode ..."
bin/magento deploy:mode:set production --skip-compilation

echo "Magento setup:upgrade"
bin/magento set:up 

echo "Magento setup:di:compile"
bin/magento set:di:co
rm -rf pub/static/frontend pub/static/adminhtml/

node themes.js


#Bundle reources to improve loads
echo "Creating magepack bundle..."
magepack bundle 


#Clean cache
echo "Cleaning cache..."
bin/magento cache:flu

#Start cron jobs
echo "Starting cron jobs"
bin/magento cron:install

echo "Giving permissions..."
#Give nginx new file permisssions
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R :www-data .

echo "Starting web servers..."
#Run web server
service varnish start
service php7.4-fpm start
service nginx start

echo "Creating let's encrypt ssl..."
certbot run --nginx --non-interactive  --agree-tos -m ${LETS_ENCRYPT_EMAIL} -d ${MAGENTO_DOMAIN} --redirect

#Run forever
tail -f /dev/null