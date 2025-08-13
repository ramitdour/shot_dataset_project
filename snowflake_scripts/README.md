
## Scripts overview

| # | Script file name                          | Purpose                                                                                                                         |
| - | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1 | `01_security_roles_users.sql`             | Create roles, role hierarchy, and the pipeline technical user.                                                                  |
| 2 | `02_warehouses_db_schemas.sql`            | Create resource monitor, warehouses, database, and schemas. Grant basic usage.                                                  |
| 3 | `03_storage_integration_stage_format.sql` | Create S3 storage integration, file format, and external stage pointing to S3 `raw_csv/`.                                       |
| 4 | `04_tables_pipe_stream_task.sql`          | Create landing and meta tables, Snowpipe with auto-ingest, change stream, curated table, and transform task.                    |
| 5 | `05_views_policies_grants.sql`            | Create analytics view, example masking policy, optional tag and network policy stub, plus final grants and ownership transfers. |

---

### Quick alignment notes

* Storage integration is now `S3_INT`. It still trusts your AWS IAM role `snowflake-storage-role-9180401308`. That is expected, since AWS resource names keep the suffix and Snowflake names do not.
* After creating `S3_INT`, run `DESC INTEGRATION S3_INT` and copy `EXTERNAL_ID` into the AWS role trust policy. Then re-run `DESC` to confirm `ENABLED` is true.
* After creating `PIPE_RAW_TO_LANDING`, run `DESC PIPE PIPE_RAW_TO_LANDING`. Copy the `notification_channel` SQS ARN into your S3 `raw_csv/*.csv` event configuration on AWS.
