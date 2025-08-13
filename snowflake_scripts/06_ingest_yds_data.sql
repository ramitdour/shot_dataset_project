-- =========================================================
-- 06_ingest_yds_data.sql
-- Create or reuse stage, infer schema for YDS landing table,
-- then load yds_data.csv from S3 -> RAW.YDS_DATA
-- =========================================================

-- Context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Ensure utility db+schema exist for stage and file format
CREATE DATABASE IF NOT EXISTS UTIL_DB;
CREATE SCHEMA  IF NOT EXISTS UTIL_DB.RAW;
USE DATABASE UTIL_DB;
USE SCHEMA RAW;

-- Storage integration must already exist and be ENABLED
-- If you just created it from 03_storage_integration_stage_format.sql, leave as is
-- ALTER STORAGE INTEGRATION S3_INT SET ENABLED = TRUE;

-- Minimal file format for CSV
CREATE OR REPLACE FILE FORMAT CSV_FF TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 0;

-- S3 stage (points to your bucket/prefix that contains yds_data.csv)
CREATE OR REPLACE STAGE S3_CSV_STAGE
  URL = 's3://clear-strategy-ramit/csv/'
  STORAGE_INTEGRATION = S3_INT
  FILE_FORMAT = CSV_FF;

-- Quick visibility check
LIST @S3_CSV_STAGE;

-- Target database and schema for the YDS tables
CREATE DATABASE IF NOT EXISTS SHOT_DATABASE;
CREATE SCHEMA  IF NOT EXISTS SHOT_DATABASE.RAW;

-- Infer a landing table from the file itself, idempotent
-- Adjust the file name if needed
CREATE OR REPLACE TABLE SHOT_DATABASE.RAW.YDS_DATA
USING TEMPLATE (
  SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION => '@UTIL_DB.RAW.S3_CSV_STAGE/yds_data.csv',
      FILE_FORMAT => 'UTIL_DB.RAW.CSV_FF'
    )
  )
);

-- Optional: preview inferred columns
SELECT * FROM SHOT_DATABASE.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME = 'YDS_DATA'
ORDER BY ORDINAL_POSITION;

-- Load the file into the landing table
USE WAREHOUSE COMPUTE_WH;
COPY INTO SHOT_DATABASE.RAW.YDS_DATA
  FROM @UTIL_DB.RAW.S3_CSV_STAGE/yds_data.csv
  FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' FIELD_DELIMITER = ',' SKIP_HEADER = 1)
  ON_ERROR = 'CONTINUE';

-- Sanity checks
SELECT COUNT(*) AS row_count FROM SHOT_DATABASE.RAW.YDS_DATA;
SELECT * FROM SHOT_DATABASE.RAW.YDS_DATA LIMIT 20;
