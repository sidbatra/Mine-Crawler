# env, seed.txt path, 

# aws credentials (CONFIG.yml or hardcoded)
# operating bucket.
# generate crawl name - timestamp

# upload resources - seed.txt, bootstrap.sh in crawl folder

# build nutch

# Bootup a new cluster and bootstrap with bootstrap.sh and hadoop config and logging in timestamped folder.
./elastic-mapreduce/elastic-mapreduce --create --hive-interactive --alive --name "My auto job" --master-instance-type m1.small --slave-instance-type m1.small --num-instances 1  --key-pair ec2-bootup --availability-zone us-east-1b --log-uri s3n://denwen-mine-crawler/logs --enable-debugging --bootstrap-action s3n://elasticmapreduce/bootstrap-actions/configure-hadoop --arg --site-key-value  --arg mapred.reduce.tasks.speculative.execution=false --arg --mapred-key-value --arg mapred.reduce.tasks.speculative.execution=false --bootstrap-action s3n://denwen-mine-crawler/bootstrap.sh


# parse job flow id
# wait until cluster is in waiting state

# upload resources to master - mr scripts, hive script, nutch deploy folder
# scp -i /home/sbat/.ssh/id_ec2_bootup -r apache-nutch-1.4-bin/runtime/deploy/ hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~
# scp -i /home/sbat/.ssh/id_ec2_bootup scripts/hive.sql scripts/mr/extract_products.rb   hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~


# run crawl.sh on master with correct folder.

# wait until crawl finishes. 
# download extracted products distributed table.
# insert into products db
