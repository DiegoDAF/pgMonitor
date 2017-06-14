CREATE TABLESPACE ts_monitoreo
  OWNER postgres
  LOCATION '/home/bases_postgres/tablespaces/ts_monitoreo';

CREATE DATABASE db_monitoreo
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = ts_monitoreo
       CONNECTION LIMIT = -1;