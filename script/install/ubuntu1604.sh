#!/bin/bash

# This will install everything required to run a basic Postal installation.
# This should be run on a clean Ubuntu 16.04 server.
#
# Once the installation has completed you will be able to access the Postal web
# interface on port 443. It will have a self-signed certificate.
#
# * Change the MySQL & RabbitMQ passwords
# * Create your first admin user with 'postal make-user'
# * Replace the self-signed certificate in /etc/nginx/ssl/postal.cert
# * Make appropriate changes to the configuration in /opt/postal/config/postal.yml
# * Setup your DNS                          [ https://github.com/atech/postal/wiki/Domains-&-DNS-Configuration ]
# * Configure the click & open tracking     [ https://github.com/atech/postal/wiki/Click-&-Open-Tracking ]
# * Configure spam & virus checking         [ https://github.com/atech/postal/wiki/Spam-&-Virus-Checking ]

set -e

#
# Dependencies
#
apt update
apt install -y software-properties-common
apt-add-repository ppa:brightbox/ruby-ng -y
apt update
export DEBIAN_FRONTEND=noninteractive
apt install -y ruby2.3 ruby2.3-dev build-essential libmysqlclient-dev nodejs git nginx wget nano
gem install bundler procodile --no-rdoc --no-ri

#
# System prep
#
useradd -r -m -d /opt/postal -s /bin/bash postal
setcap 'cap_net_bind_service=+ep' /usr/bin/ruby2.3

#
# Application Setup
#
sudo -i -u postal mkdir -p /opt/postal/app
wget https://postal.atech.media/packages/stable/latest.tgz -O - | sudo -u postal tar zxpv -C /opt/postal/app
ln -s /opt/postal/app/bin/postal /usr/bin/postal
postal bundle /opt/postal/vendor/bundle
postal initialize-config
postal initialize
postal start

#
# nginx
#
cp /opt/postal/app/resource/nginx.cfg /etc/nginx/sites-available/default
mkdir /etc/nginx/ssl/
openssl req -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/postal.key -out /etc/nginx/ssl/postal.cert -days 365 -nodes -subj "/C=GB/ST=Example/L=Example/O=Example/CN=example.com"
service nginx reload

#
# All done
#
echo
echo "Installation complete"
