CREATE TABLE public.servidores
(
  id integer NOT NULL DEFAULT nextval('servidores_id_seq'::regclass),
  estado character(2) NOT NULL,
  hostname character varying(50) NOT NULL,
  port character varying(5),
  CONSTRAINT pk_servidores PRIMARY KEY (hostname, estado)
  USING INDEX TABLESPACE ts_diego
)
WITH (
  OIDS=FALSE
);