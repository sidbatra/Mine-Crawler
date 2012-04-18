create external table pages (url string,html string) row format delimited fields terminated by '\t' stored as textfile location "/hive/pages";
load data inpath "/output/dump" into table pages;

create external table products (url string,title string,image string,store_id string,description string) row format delimited fields terminated by '\t' stored as textfile location "s3://denwen-mine-crawls/1334711638/products";

add file /home/hadoop/extract_products.rb;

insert overwrite table products select transform(url,html) using 'ruby extract_products.rb' as url,title,image,store_id,description from pages;
