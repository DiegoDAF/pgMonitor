CREATE OR REPLACE FUNCTION public.getbases(IN _serverid integer)
  RETURNS TABLE(id integer, nombre character varying) AS
$BODY$

    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select id, nombre 
	from bases
        where estado = 'AA'   -- Solo de comandos  activos   
        and server_id = _serverid
	limit 100               -- Por ahora, limitado a cien consultas

$BODY$
  LANGUAGE sql VOLATILE SECURITY DEFINER
  COST 100
  ROWS 100;