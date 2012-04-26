# Create timestamped folders in s3://denwen-mine-crawler
# Upload bootstrap.sh to base of denwen-mine-crawler
# Populate urls folders with seed.txt containing list of urls.

./elastic-mapreduce/elastic-mapreduce --create --hive-interactive --alive --name "My auto job" --master-instance-type m1.small --slave-instance-type m1.small --num-instances 1  --key-pair ec2-bootup --availability-zone us-east-1b --log-uri s3n://denwen-mine-crawler/logs --enable-debugging --bootstrap-action s3://elasticmapreduce/bootstrap-actions/configure-hadoop --args "--site-key-value mapred.reduce.tasks.speculative.execution=false --mapred-key-value mapred.reduce.tasks.speculative.execution=false"  --bootstrap-action s3://denwen-mine-crawler/bootstrap.sh

# Bootup a new cluster and bootstrap with bootstrap.sh and hadoop config and logging in timestamped folder.
#--site-key-value mapred.reduce.tasks.speculative.execution=false --mapred-key-value mapred.reduce.tasks.speculative.execution=false


# Deploy nutch & scripts on master
# scp -i /home/sbat/.ssh/id_ec2_bootup -r apache-nutch-1.4-bin/runtime/deploy/ hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~
# scp -i /home/sbat/.ssh/id_ec2_bootup scripts/hive.sql scripts/mr/extract_products.rb   hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~
# Deploy & run crawl.sh on master with correct folder.
