set hive.compute.query.using.stats=false;
set hive.mapred.mode=nonstrict;
set hive.explain.user=false;
set hive.optimize.ppd=true;
set hive.ppd.remove.duplicatefilters=true;
set hive.tez.dynamic.partition.pruning=true;
set hive.tez.dynamic.semijoin.reduction=true;
set hive.optimize.metadataonly=false;
set hive.optimize.index.filter=true;

-- Create Tables
create table alltypesorc_int ( cint int, cstring string ) stored as ORC;
create table srcpart_date (key string, value string) partitioned by (ds string ) stored as ORC;
CREATE TABLE srcpart_small(key1 STRING, value1 STRING) partitioned by (ds string) STORED as ORC;

-- Add Partitions
alter table srcpart_date add partition (ds = "2008-04-08");
alter table srcpart_date add partition (ds = "2008-04-09");

alter table srcpart_small add partition (ds = "2008-04-08");
alter table srcpart_small add partition (ds = "2008-04-09");

-- Load
insert overwrite table alltypesorc_int select cint, cstring1 from alltypesorc;
insert overwrite table srcpart_date partition (ds = "2008-04-08" ) select key, value from srcpart where ds = "2008-04-08";
insert overwrite table srcpart_date partition (ds = "2008-04-09") select key, value from srcpart where ds = "2008-04-09";
insert overwrite table srcpart_small partition (ds = "2008-04-09") select key, value from srcpart where ds = "2008-04-09";
set hive.tez.dynamic.semijoin.reduction=false;

-- single column, single key
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1);
set hive.tez.dynamic.semijoin.reduction=true;
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1);
set hive.tez.dynamic.semijoin.reduction=true;

-- Mix dynamic partition pruning(DPP) and min/max bloom filter optimizations. Should pick the DPP.
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.ds);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.ds);
set hive.tez.dynamic.semijoin.reduction=false;

--multiple sources, single key
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_small.key1 = alltypesorc_int.cstring);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_small.key1 = alltypesorc_int.cstring);
set hive.tez.dynamic.semijoin.reduction=true;
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_small.key1 = alltypesorc_int.cstring);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_small.key1 = alltypesorc_int.cstring);
set hive.tez.dynamic.semijoin.reduction=false;

-- single source, multiple keys
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1 and srcpart_date.value = srcpart_small.value1);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1 and srcpart_date.value = srcpart_small.value1);
set hive.tez.dynamic.semijoin.reduction=true;
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1 and srcpart_date.value = srcpart_small.value1);
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1 and srcpart_date.value = srcpart_small.value1);
set hive.tez.dynamic.semijoin.reduction=false;

-- multiple sources, different  keys
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_date.value = alltypesorc_int.cstring);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_date.value = alltypesorc_int.cstring);
set hive.tez.dynamic.semijoin.reduction=true;
EXPLAIN select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_date.value = alltypesorc_int.cstring);
select count(*) from srcpart_date join srcpart_small on (srcpart_date.key = srcpart_small.key1) join alltypesorc_int on (srcpart_date.value = alltypesorc_int.cstring);

drop table srcpart_date;
drop table srcpart_small;
drop table alltypesorc_int;
