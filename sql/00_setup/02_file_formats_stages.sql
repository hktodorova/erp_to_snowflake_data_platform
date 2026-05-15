use database ENTERPRISE_DWH;

create file format if not exists RAW.JSON_FORMAT
  type = json
  strip_outer_array = false;

create file format if not exists RAW.CSV_FORMAT
  type = csv
  skip_header = 1
  field_optionally_enclosed_by = '"';

create stage if not exists RAW.ERP_STAGE
  file_format = RAW.JSON_FORMAT;

create stage if not exists RAW.PAYMENT_STAGE
  file_format = RAW.JSON_FORMAT;
