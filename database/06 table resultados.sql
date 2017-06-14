CREATE TABLE public.resultados
(
  id integer NOT NULL DEFAULT nextval('resultados_id_seq'::regclass),
  server_id integer,
  consulta_id integer,
  fecha timestamp without time zone,
  resultado text,
  estado character varying(2),
  base character varying(50)
)
WITH (
  OIDS=FALSE
);