CREATE TABLE public.comandos
(
  id integer NOT NULL DEFAULT nextval('comandos_id_seq'::regclass),
  estado character(2),
  cmdsid integer,
  consulta character varying(7000),
  base character varying(50)
)
WITH (
  OIDS=FALSE
);