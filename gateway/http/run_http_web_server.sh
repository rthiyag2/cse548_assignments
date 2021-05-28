#!/bin/sh

# stop apache service
sudo systemctl stop apache2.service

#disable the site
sudo a2dissite test-and-demo

# copy the conf files in to apache2
if [ ! -f "/etc/apache2/sites-enabled/test-and-demo.conf" ]; then
	sudo cp test-and-demo.conf /etc/apache2/sites-available/.
fi

cp ports.conf /etc/apache2/.

if [ ! -f "/var/www/html/test/index.html" ]; then
	sudo mkdir /var/www/html/test
	sudo cp index.html /var/www/html/test/.
fi

# restart the apache2
sudo systemctl restart apache2.service

# enable the site
sudo a2ensite test-and-demo
sleep 5s

# reload the configuration
sudo systemctl reload apache2

