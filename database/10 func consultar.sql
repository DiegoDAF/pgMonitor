CREATE OR REPLACE FUNCTION public.consultar(
    IN _serverid integer,
    IN _version character varying,
    IN _postgresdb character varying)
  RETURNS TABLE(id integer, consulta character varying) AS
$BODY$

    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select id, consulta 
	from (
        
                select c.id, c.consulta
                from comandos c
                inner join versiones v on v.cmdsid = c.cmdsid
                   and v.valor = _version
                   and v.estado = 'AA'  -- Solo de versiones activas
                where c.estado = 'AA'   -- Solo de comandos  activos     
                and   (c.base   = _postgresdb or c.base is null)    
        
	) as temp
	limit 100               -- Por ahora, limitado a cien consultas

$BODY$
  LANGUAGE sql VOLATILE SECURITY DEFINER
  COST 100
  ROWS 100;