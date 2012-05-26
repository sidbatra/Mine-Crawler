#!/bin/bash

yes | sudo apt-get update
yes | sudo apt-get install libxslt-dev libxml2-dev
yes | sudo apt-get install ruby1.8-dev

wget http://rubyforge.org/frs/download.php/74234/rubygems-1.5.2.tgz
tar -zxf rubygems-1.5.2.tgz 
cd rubygems-1.5.2
sudo ruby setup.rb
sudo ln -f -s /usr/bin/gem1.8 /usr/bin/gem

sudo gem update --system
sudo gem install nokogiri
sudo gem install fastimage

hadoop fs -copyToLocal $1 /home/hadoop/
