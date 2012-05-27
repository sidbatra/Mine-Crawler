MINE - RAILS_ENV=production rake stores:dump:crawlable
MINE - mv hash.txt urls.txt ~/crawler/data/
CRAWLER - ruby script/automate.rb production data/urls.txt data/hash.txt ~/.ssh/id_ec2_bootup

wait to finish
check logs

terminate job flow


CRAWLER - ruby script/download.rb NAME BUCKET
MINE - RAILS_ENV=production rake products:import:crawled dir=~/crawler/NAME/products
MINE - RAILS_ENV=prouction rake sunspot:solr:index
