#!/bin/bash

bin/nutch crawl s3n://denwen-mine-crawl-logs/settings/urls -depth 10 -topN 100000 -dir /crawl -threads 20 &> crawl.txt 
bin/nutch readseg -dump /crawl/segments/*  /output  -nogenerate -noparse -noparsedata -noparsetext &> readseg.txt
hive -f "hive.sql" &> hive.txt


