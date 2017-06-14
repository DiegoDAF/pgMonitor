CREATE TABLE public.bases
(
  id integer NOT NULL DEFAULT nextval('bases_id_seq'::regclass),
  estado character(2) NOT NULL DEFAULT 'AA'::bpchar,
  server_id integer,
  nombre character varying(50),
  CONSTRAINT pk_bases_id PRIMARY KEY (id),
  CONSTRAINT uq_bases_server_id_base UNIQUE (server_id, nombre)
)
WITH (
  OIDS=FALSE
);