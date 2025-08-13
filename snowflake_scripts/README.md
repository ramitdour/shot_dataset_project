## Scripts overview

| # | Script file name                          | Purpose                                                                                                                         |
| - | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1 | `01_security_roles_users.sql`             | Create roles, role hierarchy, and the pipeline technical user.                                                                  |
| 2 | `02_warehouses_db_schemas.sql`            | Create resource monitor, warehouses, database, and schemas. Grant basic usage.                                                  |
| 3 | `03_storage_integration_stage_format.sql` | Create S3 storage integration, file format, and external stage pointing to S3 `raw_csv/`.                                       |
| 4 | `04_tables_pipe_stream_task.sql`          | Create landing and meta tables, Snowpipe with auto-ingest, change stream, curated table, and transform task.                    |
| 5 | `05_views_policies_grants.sql`            | Create analytics view, example masking policy, optional tag and network policy stub, plus final grants and ownership transfers. |
| 6 | `06_ingest_yds_data.sql`                  | Ingest YDS CSV from the S3 stage into `RAW.YDS_DATA` (creates or reuses stage and file format if needed).                       |
| 7 | `07_clean_yds_data.sql`                   | Build `RAW.YDS_TRANSFORMED` with safe casts, then `RAW.YDS_CLEANED` with imputations and features.                              |

---

### Quick alignment notes

* Storage integration is `S3_INT`. It still trusts your AWS IAM role `snowflake-storage-role-9180401308`. This is expected, since AWS resource names keep the suffix and Snowflake names do not.
* After creating `S3_INT`, run `DESC INTEGRATION S3_INT` and copy `EXTERNAL_ID` into the AWS role trust policy. Then run `DESC` again to confirm `ENABLED` is true.
* After creating `PIPE_RAW_TO_LANDING`, run `DESC PIPE PIPE_RAW_TO_LANDING`. Copy the `notification_channel` SQS ARN into your S3 `raw_csv/*.csv` event configuration on AWS.
* If you are using a utility stage like `UTIL_DB.RAW.S3_CSV_STAGE` during bootstrap, keep it consistent in `06_ingest_yds_data.sql`. In production you can point `STG_RAW_CSV` at the same S3 prefix and rely on the pipe to auto-ingest.
* Recommended run order: 01 → 02 → 03 → 04 → 05. Use 06 for manual loads or backfills when needed, then run 07 to produce the cleaned table.
