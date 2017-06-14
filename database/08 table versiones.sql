CREATE TABLE public.versiones
(
  id integer NOT NULL DEFAULT nextval('versiones_id_seq'::regclass),
  estado character(2),
  valor character varying(6),
  cmdsid integer
)
WITH (
  OIDS=FALSE
);