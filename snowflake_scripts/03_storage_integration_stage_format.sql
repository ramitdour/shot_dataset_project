-- Storage integration must be created by ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

-- Storage Integration for S3
-- After this, run: DESC INTEGRATION S3_INT;
-- Copy EXTERNAL_ID and add it to your AWS IAM role trust policy.
CREATE OR REPLACE STORAGE INTEGRATION S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<AWS_ROLE_ARN_FROM_AWS_snowflake-storage-role-9180401308>'
  STORAGE_AWS_EXTERNAL_ID = '<EXTERNAL_ID_FROM_DESC_INTEGRATION>'
  STORAGE_ALLOWED_LOCATIONS = ('s3://<S3_BUCKET_NAME>/raw_csv/')
  COMMENT = 'Integration to S3 raw_csv using AWS role snowflake-storage-role-9180401308';

-- Permit pipeline role to use the integration
GRANT USAGE ON INTEGRATION S3_INT TO ROLE ROLE_PIPELINE;

-- Switch to SYSADMIN for data objects
USE ROLE SYSADMIN;
USE DATABASE CLEAR_STRATEGY_DB;

-- File format for clean CSV
CREATE OR REPLACE FILE FORMAT FF_CSV_CLEAN
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  NULL_IF = ('', 'NULL', 'null')
  ENCODING = 'UTF8'
  COMMENT = 'Standard CSV with a single header row';

-- External stage pointing to S3 raw_csv prefix
CREATE OR REPLACE STAGE STG_RAW_CSV
  URL = 's3://<S3_BUCKET_NAME>/raw_csv/'
  STORAGE_INTEGRATION = S3_INT
  FILE_FORMAT = FF_CSV_CLEAN
  COMMENT = 'Stage for sanitized CSV emitted by the processor Lambda';

-- Allow pipeline role to read from the stage
GRANT USAGE ON STAGE STG_RAW_CSV TO ROLE ROLE_PIPELINE;
