set hive.stats.fetch.column.stats=true;

create table if not exists loc_staging (
  state string,
  locid int,
  zip bigint,
  year int
) row format delimited fields terminated by '|' stored as textfile;

create table loc_orc like loc_staging;
alter table loc_orc set fileformat orc;

load data local inpath '../../data/files/loc.txt' overwrite into table loc_staging;

insert overwrite table loc_orc select * from loc_staging;

-- numRows: 8 rawDataSize: 796
explain select * from loc_orc;

-- partial column stats
analyze table loc_orc compute statistics for columns state;

-- inner group by: map - numRows: 8 reduce - numRows: 4
-- outer group by: map - numRows: 4 reduce numRows: 2
explain select a, c, min(b)
from ( select state as a, locid as b, count(*) as c
       from loc_orc
       group by state,locid
     ) sq1
group by a,c;

analyze table loc_orc compute statistics for columns state,locid,zip,year;

-- only one distinct value in year column + 1 NULL value
-- map-side GBY: numRows: 8 (map-side will not do any reduction)
-- reduce-side GBY: numRows: 2
explain select year from loc_orc group by year;

-- map-side GBY: numRows: 8
-- reduce-side GBY: numRows: 4
explain select state,locid from loc_orc group by state,locid;

-- map-side GBY numRows: 32 reduce-side GBY numRows: 16
explain select state,locid from loc_orc group by state,locid with cube;

-- map-side GBY numRows: 24 reduce-side GBY numRows: 12
explain select state,locid from loc_orc group by state,locid with rollup;

-- map-side GBY numRows: 8 reduce-side GBY numRows: 4
explain select state,locid from loc_orc group by state,locid grouping sets((state));

-- map-side GBY numRows: 16 reduce-side GBY numRows: 8
explain select state,locid from loc_orc group by state,locid grouping sets((state),(locid));

-- map-side GBY numRows: 24 reduce-side GBY numRows: 12
explain select state,locid from loc_orc group by state,locid grouping sets((state),(locid),());

-- map-side GBY numRows: 32 reduce-side GBY numRows: 16
explain select state,locid from loc_orc group by state,locid grouping sets((state,locid),(state),(locid),());

set hive.stats.map.parallelism=10;

-- map-side GBY: numRows: 80 (map-side will not do any reduction)
-- reduce-side GBY: numRows: 2 Reason: numDistinct of year is 2. numRows = min(80/2, 2)
explain select year from loc_orc group by year;

-- map-side GBY numRows: 320 reduce-side GBY numRows: 42 Reason: numDistinct of state and locid are 6,7 resp. numRows = min(320/2, 6*7)
explain select state,locid from loc_orc group by state,locid with cube;

set hive.stats.fetch.column.stats=false;
set hive.stats.map.parallelism=1;

-- map-side GBY numRows: 32 reduce-side GBY numRows: 16
explain select state,locid from loc_orc group by state,locid with cube;

-- map-side GBY numRows: 24 reduce-side GBY numRows: 12
explain select state,locid from loc_orc group by state,locid with rollup;

-- map-side GBY numRows: 8 reduce-side GBY numRows: 4
explain select state,locid from loc_orc group by state,locid grouping sets((state));

-- map-side GBY numRows: 16 reduce-side GBY numRows: 8
explain select state,locid from loc_orc group by state,locid grouping sets((state),(locid));

-- map-side GBY numRows: 24 reduce-side GBY numRows: 12
explain select state,locid from loc_orc group by state,locid grouping sets((state),(locid),());

-- map-side GBY numRows: 32 reduce-side GBY numRows: 16
explain select state,locid from loc_orc group by state,locid grouping sets((state,locid),(state),(locid),());

set hive.stats.map.parallelism=10;

-- map-side GBY: numRows: 80 (map-side will not do any reduction)
-- reduce-side GBY: numRows: 2 Reason: numDistinct of year is 2. numRows = min(80/2, 2)
explain select year from loc_orc group by year;

-- map-side GBY numRows: 320 reduce-side GBY numRows: 42 Reason: numDistinct of state and locid are 6,7 resp. numRows = min(320/2, 6*7)
explain select state,locid from loc_orc group by state,locid with cube;

