MINE - RAILS_ENV=production rake stores:dump:crawlable
MINE - mv hash.txt urls.txt ~/crawler/data/
CRAWLER - ruby script/automate.rb production data/urls.txt data/hash.txt ~/.ssh/id_ec2_bootup

wait to finish
check logs

terminate job flow
