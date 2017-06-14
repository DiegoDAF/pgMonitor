CREATE TABLE public.parametros
(
  id integer NOT NULL DEFAULT nextval('parametros_id_seq'::regclass),
  server_id integer,
  consulta_id integer,
  sentido integer,
  valor numeric(10,2),
  CONSTRAINT pk_parametros_id PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);