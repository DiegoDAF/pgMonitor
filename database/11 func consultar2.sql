CREATE OR REPLACE FUNCTION public.consultar2(
    IN _serverid integer,
    IN _version character varying,
    IN _postgresdb character varying)
  RETURNS TABLE(id integer, base character varying, consulta character varying) AS
$BODY$

    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select id, base, consulta 
	from (

                select c.id, b.nombre base, c.consulta
                from comandos c
                inner join versiones v on v.cmdsid = c.cmdsid
                        and v.valor = _version
                        and v.estado = 'AA'  -- Solo versiones activas
                inner join bases b on b.server_id = _serverid
                        and b.estado = 'AA'  -- Solo bases activas
                where c.estado = 'AA'   -- Solo comandos  activos     
                and c.base is null
                
        
        
	) as temp
	limit 100               -- Por ahora, limitado a cien consultas

$BODY$
  LANGUAGE sql VOLATILE SECURITY DEFINER
  COST 100
  ROWS 100;