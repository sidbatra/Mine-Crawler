#!/bin/bash

hadoop distcp s3n://denwen-mine-crawls/crawl /crawl

bin/nutch crawl s3n://denwen-mine-crawls/1334711638/urls -depth 12 -topN 100000 -dir /crawl -threads 40 &> crawl.txt 
bin/nutch readseg -dump /crawl/segments/*  /output  -nogenerate -noparse -noparsedata -noparsetext &> readseg.txt
hive -f "hive.sql" &> hive.txt

# Create backup of current crawl on s3
#
hadoop distcp -overwrite /crawl s3n://denwen-mine-crawls/crawl

