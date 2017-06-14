CREATE TABLE public.acciones
(
  id integer NOT NULL DEFAULT nextval('acciones_id_seq'::regclass),
  descripcion character varying(100),
  CONSTRAINT pk_acciones_id PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);