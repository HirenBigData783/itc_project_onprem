CREATE DATABASE IF NOT EXISTS tfl_proj_hiren;

USE tfl_proj_hiren;

DROP TABLE IF EXISTS dim_stations;
CREATE EXTERNAL TABLE dim_stations (
  station_id INT,
  nlc INT,
  station_name STRING,
  london_underground STRING,
  elizabeth_line STRING,
  london_overground STRING,
  dlr STRING,
  night_tube STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/dim_stations';

DROP TABLE IF EXISTS fact_station_lines;
CREATE EXTERNAL TABLE fact_station_lines (
  station_id INT,
  line_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/fact_station_lines';

DROP TABLE IF EXISTS fact_passenger_entry_exit;
CREATE EXTERNAL TABLE fact_passenger_entry_exit (
  station_id INT,
  date_id INT,
  entry_exit_count BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/fact_passenger_entry_exit';

DROP TABLE IF EXISTS dim_networks;
CREATE EXTERNAL TABLE dim_networks (
  network_id INT,
  network_name STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/dim_networks';

DROP TABLE IF EXISTS dim_lines;
CREATE EXTERNAL TABLE dim_lines (
  line_id INT,
  line_name STRING,
  network_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/dim_lines';

DROP TABLE IF EXISTS dim_date;
CREATE EXTERNAL TABLE dim_date (
  date_id INT,
  year INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
STORED AS TEXTFILE
LOCATION '/tmp/hiren/tfl_proj/tfl_data/dim_date';
