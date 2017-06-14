CREATE OR REPLACE FUNCTION public.guardar(
    IN _server_id integer,
    IN _consulta_id integer,
    IN _base character varying,
    IN _resultado text)
  RETURNS TABLE(id integer, accion integer) AS
$BODY$
BEGIN 

    -- 20170607 DAF Making Magic!

    CASE _consulta_id  -- Por cada respuesta debo hacer algo o no...
    WHEN 2 THEN
        INSERT INTO public.bases(estado, server_id, nombre) 
        values( 'AA', _server_id, unnest(string_to_array (_resultado, chr(10)))   )
        ON CONFLICT ( server_id, nombre ) 
        DO UPDATE SET estado = 'AA'
        ;
    ELSE
    END CASE;

    RETURN QUERY

    insert into public.resultados(server_id, consulta_id, fecha, resultado, estado, base) 
    values (_server_id, _consulta_id, now(), _resultado, 'AA', _base)
    returning resultados.id, 1; -- Reemplazar 1 por accion: 1 ok, 2 mandar mail error

    
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100
  ROWS 100;
