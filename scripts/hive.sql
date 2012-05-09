create external table pages (url string,html string) row format delimited fields terminated by '\t' stored as textfile location "/hive/pages";
load data inpath "/output/dump" into table pages;
create external table products_map (url string,title string,image string,store_id string,description string) row format delimited fields terminated by '\t' stored as textfile location "/hive/products_map";
create external table products (url string,title string,image string,store_id string,description string) row format delimited fields terminated by '\t' stored as textfile location "/hive/products";

add file /home/hadoop/scripts/mr/extract_products.rb;
add file /home/hadoop/scripts/mr/reduce_products.rb;

from(from pages map url,html using 'ruby extract_products.rb' as url,title,image,store_id,description distribute by image) map_products insert overwrite table products reduce url,title,image,store_id,description using 'ruby reduce_products.rb' as url,title,image,store_id,description;

--insert overwrite table products select transform(url,html) using 'ruby extract_products.rb' as url,title,image,store_id,description from pages;
