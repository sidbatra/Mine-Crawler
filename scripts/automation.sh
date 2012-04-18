
# Create timestamped folders in s3://denwen-mine-crawls
# Populate urls folders with seed.txt containing list of urls.
# Bootup a new cluster and bootstrap with bootstrap.sh and hadoop config and logging in timestamped folder.
#--site-key-value mapred.reduce.tasks.speculative.execution=false --mapred-key-value mapred.reduce.tasks.speculative.execution=false
# Deploy nutch on master
# scp -i /home/sbat/.ssh/id_ec2_bootup -r apache-nutch-1.4-bin/runtime/deploy/ hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~
# Deploy & run crawl.sh on master with correct folder.
