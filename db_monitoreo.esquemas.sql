--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'md5a802b42f81c1dd24ffea066b7b81b30a';

--
-- Tablespaces
--

CREATE TABLESPACE ts_monitoreo OWNER postgres LOCATION '/home/bases_postgres/tablespaces/ts_monitoreo';


--
-- Database creation
--

CREATE DATABASE db_monitoreo WITH TEMPLATE = template0 OWNER = postgres TABLESPACE = ts_monitoreo;
REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;

\connect db_monitoreo

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 10.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: db_monitoreo; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE db_monitoreo IS 'DAF was here!';


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: pgbouncer
--

CREATE SCHEMA pgbouncer;


ALTER SCHEMA pgbouncer OWNER TO pgbouncer;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


SET search_path = pgbouncer, pg_catalog;

--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: postgres
--

CREATE FUNCTION get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RAISE WARNING 'PgBouncer auth request: %', p_usename;
 
    RETURN QUERY
    SELECT usename::TEXT, passwd::TEXT FROM pg_catalog.pg_shadow
     WHERE usename = p_usename;
END;
$$;


ALTER FUNCTION pgbouncer.get_auth(p_usename text) OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: consulta_42(integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION consulta_42(_ids integer[]) RETURNS TABLE(resultado text)
    LANGUAGE plpgsql SECURITY DEFINER ROWS 100
    AS $$

declare

cant     integer;

begin

	cant := (select count(*) from(	select '' as hostname,
	 'pid|Usuario|Base|Programa|Inicio_Query|Tiempo_Ejecucion|Ultimo_Cambio|Consulta' as resultado,now() as Fecha_Recoleccion
	  union all
	SELECT s.hostname as Server, r.resultado,r.fecha as Fecha_Recoleccion
	FROM public.resultados r
	inner join servidores s on s.id = r.server_id
	where r.resultado <> '' and
	r.id in (select unnest(_ids)) and
	r.consulta_id = 4)as cant);

		if cant > 1 then
			RETURN QUERY
			/*select '<table border="1">'||'<tr>'||
			'<th>'||'Hostname'||'</th>'||
			'<th>'||'pid'||'</th>'||'<th>'||'Usuario'||'</th>'||'<th>'||'Base'||'</th>'||'<th>'||'Programa'||'</th>'||'<th>'||'Inicio_Query'||'</th>'||'<th>'||'Tiempo_Ejecucion'||'</th>'||'<th>'||'Ultimo_Cambio'||'</th>'||'<th>'||'Consulta'||'</th>'||
			'<th>'||'Fecha_Recoleccion'||'</th>'||
			'</tr>'
			--'<th>'||''||'</th>'||'</tr>'
			  union all
			SELECT '<tr><td>'||s.hostname||'</td>'||'<td>'||replace(replace(r.resultado,'|','</td><td>'),';;','</td><td>'||r.fecha||'</td></tr><tr><td>'||s.hostname||'</td><td>')
			--||'<td>'||r.fecha||'</td>'
			||'</tr></table>'
			FROM public.resultados r
			inner join servidores s on s.id = r.server_id
			where r.resultado <> '' and
			r.id in (select unnest(_ids)) and
			r.consulta_id = 4;*/

            select '<table border="1"><tr>'||
                    '<th>Host/IP</th> <th>Fecha</th> <th>PId</th> <th>Usuario</th> <th>Base</th> <th> Programa </th> <th> Inicio Query </th> <th> Tiempo Ejecucion </th>  <th> Ultimo_Cambio</th> '||
                     '</tr>'
            union all
            select  '<tr><td>' || s.hostname ||'</td><td>'|| r.fecha ||'</td><td>'||
                split_part(r.resultado, '|', 1) ||'</td><td>'||
                split_part(r.resultado, '|', 2) ||'</td><td>'||
                split_part(r.resultado, '|', 3) ||'</td><td>'||
                split_part(r.resultado, '|', 4) ||'</td><td>'||
                split_part(r.resultado, '|', 5) ||'</td><td>'||
                split_part(r.resultado, '|', 6) ||'</td><td>'||
                split_part(r.resultado, '|', 7) ||'</td>'||
                '</tr><tr><th colspan="9">Consulta</td>'||
                '</tr><tr><td colspan="9">'||
                split_part(unnest(string_to_array(r.resultado,';;')), '|', 8) 
                ||'</td></tr>'
            FROM public.resultados r
            inner join servidores s on s.id = r.server_id
            where r.resultado <> '' and
			r.id in (select unnest(_ids)) and
			r.consulta_id = 4
            union all
            select '</table>';

		end if;
end;
$$;


ALTER FUNCTION public.consulta_42(_ids integer[]) OWNER TO postgres;

--
-- Name: consultar(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION consultar(_serverid integer, _version character varying, _postgresdb character varying) RETURNS TABLE(id integer, consulta character varying)
    LANGUAGE sql SECURITY DEFINER ROWS 100
    AS $$


    -- 2017-08-08 DAF Agrego el _postgresdb <> ''
    -- 2017-07-11 DAF Agrego replace por parametro
    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select id, consulta 
	from (
        
        select c.id,
        replace(c.consulta, '--VALOT--', coalesce(
                (
                    
                    select valort 
                    from parametros
                    where consulta_id = c.id 
                      and ( server_id = _serverid or server_id is null ) 
                      and paramname = 'LASTVACUUM'
                    order by sentido desc limit 1
                    
                )
                  , '') ) as consulta
        from comandos c
        inner join versiones v on v.cmdsid = c.cmdsid
           and v.valor = _version
           and v.estado = 'AA'  -- Solo de versiones activas
        --left join parametros p on p.server_id = _serverid
            
        where c.estado = 'AA'   -- Solo de comandos  activos     
        and   (c.base   = _postgresdb or c.base is null)    
        and _postgresdb <> ''

	) as temp
	limit 100               -- Por ahora, limitado a cien consultas


$$;


ALTER FUNCTION public.consultar(_serverid integer, _version character varying, _postgresdb character varying) OWNER TO postgres;

--
-- Name: consultar2(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION consultar2(_serverid integer, _version character varying, _postgresdb character varying) RETURNS TABLE(id integer, base character varying, consulta character varying)
    LANGUAGE sql SECURITY DEFINER ROWS 100
    AS $$


    -- 2017-07-11 DAF Agrego replace por parametro
    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select distinct id, base, consulta 
	from (
            select c.id, b.nombre base, 
        
        replace(c.consulta, '--VALOT--', coalesce(
                (
                    
                    select valort 
                    from parametros
                    where consulta_id = c.id 
                      and ( server_id = _serverid or server_id is null ) 
                      and paramname = 'LASTVACUUM'
                    order by sentido desc limit 1
                    
                )
                  , '') ) as consulta
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


$$;


ALTER FUNCTION public.consultar2(_serverid integer, _version character varying, _postgresdb character varying) OWNER TO postgres;

--
-- Name: fn_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF    ( extract(hour from NEW.fecha) = 0 ) THEN INSERT INTO resultados_child_0 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 1 ) THEN INSERT INTO resultados_child_1 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 2 ) THEN INSERT INTO resultados_child_2 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 3 ) THEN INSERT INTO resultados_child_3 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 4 ) THEN INSERT INTO resultados_child_4 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 5 ) THEN INSERT INTO resultados_child_5 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 6 ) THEN INSERT INTO resultados_child_6 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 7 ) THEN INSERT INTO resultados_child_7 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 8 ) THEN INSERT INTO resultados_child_8 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 9 ) THEN INSERT INTO resultados_child_9 VALUES (NEW.*);

    ELSIF ( extract(hour from NEW.fecha) = 10 ) THEN INSERT INTO resultados_child_10 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 11 ) THEN INSERT INTO resultados_child_11 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 12 ) THEN INSERT INTO resultados_child_12 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 13 ) THEN INSERT INTO resultados_child_13 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 14 ) THEN INSERT INTO resultados_child_14 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 15 ) THEN INSERT INTO resultados_child_15 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 16 ) THEN INSERT INTO resultados_child_16 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 17 ) THEN INSERT INTO resultados_child_17 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 18 ) THEN INSERT INTO resultados_child_18 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 19 ) THEN INSERT INTO resultados_child_19 VALUES (NEW.*);

    ELSIF ( extract(hour from NEW.fecha) = 20 ) THEN INSERT INTO resultados_child_20 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 21 ) THEN INSERT INTO resultados_child_21 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 22 ) THEN INSERT INTO resultados_child_22 VALUES (NEW.*);
    ELSIF ( extract(hour from NEW.fecha) = 23 ) THEN INSERT INTO resultados_child_23 VALUES (NEW.*);

    ELSE INSERT INTO resultados_child_14 VALUES (NEW.*);
    
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_insert() OWNER TO postgres;

--
-- Name: fn_ressize_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_ressize_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF    ( NEW.fecha_insert::date < '20170101'::date)                  THEN INSERT INTO ressize_child_2016   VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170101' and '20170131' ) THEN INSERT INTO ressize_child_201701 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170201' and '20170228' ) THEN INSERT INTO ressize_child_201702 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170301' and '20170331' ) THEN INSERT INTO ressize_child_201703 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170401' and '20170430' ) THEN INSERT INTO ressize_child_201704 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170501' and '20170531' ) THEN INSERT INTO ressize_child_201705 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170601' and '20170630' ) THEN INSERT INTO ressize_child_201706 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170701' and '20170731' ) THEN INSERT INTO ressize_child_201707 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170801' and '20170831' ) THEN INSERT INTO ressize_child_201708 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20170901' and '20170930' ) THEN INSERT INTO ressize_child_201709 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20171001' and '20171031' ) THEN INSERT INTO ressize_child_201710 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20171101' and '20171130' ) THEN INSERT INTO ressize_child_201711 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20171201' and '20171231' ) THEN INSERT INTO ressize_child_201712 VALUES (NEW.*);
                                                                                                       
    ELSIF ( NEW.fecha_insert::date between DATE '20180101' and '20180131' ) THEN INSERT INTO ressize_child_201801 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180201' and '20180228' ) THEN INSERT INTO ressize_child_201802 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180301' and '20180331' ) THEN INSERT INTO ressize_child_201803 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180401' and '20180430' ) THEN INSERT INTO ressize_child_201804 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180501' and '20180531' ) THEN INSERT INTO ressize_child_201805 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180601' and '20180630' ) THEN INSERT INTO ressize_child_201806 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180701' and '20180731' ) THEN INSERT INTO ressize_child_201807 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180801' and '20180831' ) THEN INSERT INTO ressize_child_201808 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20180901' and '20180930' ) THEN INSERT INTO ressize_child_201809 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20181001' and '20181031' ) THEN INSERT INTO ressize_child_201810 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20181101' and '20181130' ) THEN INSERT INTO ressize_child_201811 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20181201' and '20181231' ) THEN INSERT INTO ressize_child_201812 VALUES (NEW.*);
                                                                                                       
    ELSIF ( NEW.fecha_insert::date between DATE '20190101' and '20190131' ) THEN INSERT INTO ressize_child_201901 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190201' and '20190228' ) THEN INSERT INTO ressize_child_201902 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190301' and '20190331' ) THEN INSERT INTO ressize_child_201903 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190401' and '20190430' ) THEN INSERT INTO ressize_child_201904 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190501' and '20190531' ) THEN INSERT INTO ressize_child_201905 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190601' and '20190630' ) THEN INSERT INTO ressize_child_201906 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190701' and '20190731' ) THEN INSERT INTO ressize_child_201907 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190801' and '20190831' ) THEN INSERT INTO ressize_child_201908 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20190901' and '20190930' ) THEN INSERT INTO ressize_child_201909 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20191001' and '20191031' ) THEN INSERT INTO ressize_child_201910 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20191101' and '20191130' ) THEN INSERT INTO ressize_child_201911 VALUES (NEW.*);
    ELSIF ( NEW.fecha_insert::date between DATE '20191201' and '20191231' ) THEN INSERT INTO ressize_child_201912 VALUES (NEW.*);

    ELSE
        RAISE EXCEPTION 'Date out of range';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_ressize_insert() OWNER TO postgres;

--
-- Name: getbases(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getbases(_serverid integer) RETURNS TABLE(id integer, nombre character varying)
    LANGUAGE sql SECURITY DEFINER ROWS 100
    AS $$

    -- 2017-06-09 DAF Agrego condiciion al where
    -- 2017-06-06 DAF Version inicial, making magic

	select id, nombre 
	from bases
        where estado = 'AA'   -- Solo de comandos  activos   
        and server_id = _serverid
	limit 100               -- Por ahora, limitado a cien consultas

$$;


ALTER FUNCTION public.getbases(_serverid integer) OWNER TO postgres;

--
-- Name: guardar(integer, integer, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION guardar(_server_id integer, _consulta_id integer, _base character varying, _resultado text) RETURNS TABLE(id integer, accion integer)
    LANGUAGE plpgsql SECURITY DEFINER ROWS 100
    AS $$
BEGIN 

    -- 20180410 DAF Saco los enter en los querys del 12
    -- 20170703 DAF Desactivo las bases para luego activar las que siguen vivas
    -- 20170607 DAF Making Magic!


    if _resultado != '' then -- no grabo si no hay nada.

	CASE _consulta_id  -- Por cada respuesta debo hacer algo o no...
	WHEN 2 THEN
		update public.bases 
		set estado = 'AZ', fecha_delete = clock_timestamp(), fecha_update = clock_timestamp()
		where server_id = _server_id;

		INSERT INTO public.bases(estado, server_id, nombre, version) 
		values( 'AA', _server_id, unnest(string_to_array (_resultado, ';;')), 1 )
		ON CONFLICT ( server_id, nombre ) 
		DO UPDATE SET estado = 'AA', fecha_delete = null, fecha_update = clock_timestamp(), version = EXCLUDED.version + 1 
		; 
	WHEN 12 THEN
		RAISE NOTICE 'Before: %', _resultado;
		
		_resultado := regexp_replace(_resultado, '\n', ';;');
		_resultado := regexp_replace(_resultado, '\r', ';;');

		RAISE NOTICE 'After: %', _resultado;
	ELSE
	END CASE;

	RETURN QUERY

	insert into public.resultados(server_id, consulta_id, fecha, resultado, estado, base) 
	values (_server_id, _consulta_id, clock_timestamp(), _resultado, 'AA', _base)
	returning resultados.id, 1; -- Reemplazar 1 por accion: 1 ok, 2 mandar mail error

    end if;  
    
END
$$;


ALTER FUNCTION public.guardar(_server_id integer, _consulta_id integer, _base character varying, _resultado text) OWNER TO postgres;

--
-- Name: guardar_tmp(integer, integer, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION guardar_tmp(_server_id integer, _consulta_id integer, _base character varying, _resultado text) RETURNS TABLE(id integer, accion integer)
    LANGUAGE plpgsql SECURITY DEFINER ROWS 100
    AS $$
BEGIN 

    -- 20180410 DAF Saco los enter en los querys del 12
    -- 20170703 DAF Desactivo las bases para luego activar las que siguen vivas
    -- 20170607 DAF Making Magic!

    if _resultado != '' then -- no grabo si no hay nada.

	CASE _consulta_id  -- Por cada respuesta debo hacer algo o no...
	WHEN 2 THEN
		update public.bases 
		set estado = 'AZ', fecha_delete = clock_timestamp(), fecha_update = clock_timestamp()
		where server_id = _server_id;

		INSERT INTO public.bases(estado, server_id, nombre, version) 
		values( 'AA', _server_id, unnest(string_to_array (_resultado, chr(10))), 1 )
		ON CONFLICT ( server_id, nombre ) 
		DO UPDATE SET estado = 'AA', fecha_delete = null, fecha_update = clock_timestamp(), version = EXCLUDED.version + 1 
		; 
	WHEN 12 THEN
		RAISE NOTICE 'Before: %', _resultado;
		
		_resultado := regexp_replace(_resultado, '\n', ';;');
		_resultado := regexp_replace(_resultado, '\r', ';;');

		RAISE NOTICE 'After: %', _resultado;
	ELSE
	END CASE;

	RETURN QUERY

	insert into public.resultados(server_id, consulta_id, fecha, resultado, estado, base) 
	values (_server_id, _consulta_id, clock_timestamp(), _resultado, 'AA', _base)
	returning resultados.id, 1; -- Reemplazar 1 por accion: 1 ok, 2 mandar mail error

    end if;  
    
END
$$;


ALTER FUNCTION public.guardar_tmp(_server_id integer, _consulta_id integer, _base character varying, _resultado text) OWNER TO postgres;

--
-- Name: informa_resultados(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION informa_resultados() RETURNS TABLE(id integer[])
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare

	id_consulta			integer;
	ids              		integer[];
	resultados    		record;
	
	cur_resultados	cursor for
		--select 1 as consulta_id, 2 as idd;
		SELECT r.consulta_id, array_agg(r.id) as idd
		FROM public.resultados r
		where r.estado = 'AA'
		group by r.consulta_id;
			
	

begin

		open cur_resultados;
		loop
			fetch cur_resultados into resultados;
			exit when not found;
			begin
			--id_consulta := resultados.consulta_id;
			--ids := resultados.idd;

			
			
			
			if (resultados.consulta_id = 1) then
				update public.resultados set estado = 'AZ' where id in ( ids );
				RETURN QUERY select resultados.idd;
			elseif (resultados.consulta_id = 2) then
				update public.resultados set estado = 'AD' where id in ( ids );
				RETURN QUERY select resultados.idd;
			elseif (resultados.consulta_id = 3) then
				RETURN QUERY select resultados.idd;
			elseif (resultados.consulta_id = 4) then
				RETURN QUERY select resultados.idd;
			elseif (resultados.consulta_id = 5) then
				RETURN QUERY select resultados.idd;
			else 
				RETURN QUERY select resultados.idd;
			end if;
			
			end;
			
		end loop;
		close cur_resultados;
	
		exception
						when others then
							raise notice '% (%)',SQLSTATE, SQLERRM;
	
	


end;

$$;


ALTER FUNCTION public.informa_resultados() OWNER TO postgres;

--
-- Name: procchildeight(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildeight(_rid integer, _serverid integer, _consultaid integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE _sql text;
    DECLARE _sdestino text; 
BEGIN


    -- 20171128 DAF Agrego el rid
    -- 20171122 DAF Agrego los comandos de vacuum
    -- 20170811 DAF Agrego la busqueda de los destinatarios del mail.

   _sdestino := (  select string_agg(valort, ',') as destinos
                    from (
                        select valort
                        from parametros
                        where consulta_id = _consultaid
                        and paramname = 'EMAILTO'
                        and ( 
                            server_id = _serverid
                            or 
                            server_id is null
                            )
                        group by valort
                        ) tmp
                    limit 1 
                 ); 
                 
    -- _sdestino := 'dfeito@conexia.com';

    RAISE NOTICE 'Destinatarios: %', _sdestino;

    _sql := 'copy ( select htm from ( select 10, ''<table border="1"><tr><th>Host</th><th>Puerto</th><th>Base</th> </tr><tr><td>'' htm union select 15, servidores.hostname || ''</td><td>'' || servidores.port || ''</td><td>'' ||resultados.base || ''</td></tr><tr>'' from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 20, ''<th>Tabla</th><th>AutoAnalyze</th><th>Analyze</th></tr> <tr><td>'' union select 25, replace(replace(resultado,''|'',''</td><td>&nbsp;''), '';;'', ''</td></tr><tr><td>'') from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 30, ''</td></tr></table>'' union select 40, ''<p><pre>'' union select 50, ''psql -U postgres -c "VACUUM ANALYZE VERBOSE ''|| split_part( unnest( string_to_array( resultados.resultado, chr(10) ) ), ''|'', 1) ||'';" -h ''|| servidores.hostname ||'' -p ''|| servidores.port ||'' -d ''|| resultados.base ||'' & '' from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 60, ''</pre></p>'' union select 70, ''<p>rid: '|| _rid::text ||'</p>'' order by 1 ) tmp ) to program ''mutt   -e "set content_type=text/html" -s "MONITOREO - Problemas de Vacuum Analyze" -- '|| _sdestino ||' '' with (format text);';

    RAISE NOTICE 'SQL: %', _sql;

    EXECUTE _sql;
    RETURN;

END;

$$;


ALTER FUNCTION public.procchildeight(_rid integer, _serverid integer, _consultaid integer) OWNER TO postgres;

--
-- Name: procchildeight_test(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildeight_test(_rid integer, _serverid integer, _consultaid integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE _sql text;
    DECLARE _sdestino text; 
BEGIN


    -- 20171128 DAF Agrego el rid
    -- 20171122 DAF Agrego los comandos de vacuum
    -- 20170811 DAF Agrego la busqueda de los destinatarios del mail.

   _sdestino := (  select string_agg(valort, ',') as destinos
                    from (
                        select valort
                        from parametros
                        where consulta_id = _consultaid
                        and paramname = 'EMAILTO'
                        and ( 
                            server_id = _serverid
                            or 
                            server_id is null
                            )
                        group by valort
                        ) tmp
                    limit 1 
                 ); 
                 
    -- _sdestino := 'dfeito@conexia.com';

    RAISE NOTICE 'Destinatarios: %', _sdestino;

    _sql := 'copy ( select htm from ( select 10, ''<table border="1"><tr><th>Host</th><th>Puerto</th><th>Base</th> </tr><tr><td>'' htm union select 15, servidores.hostname || ''</td><td>'' || servidores.port || ''</td><td>'' ||resultados.base || ''</td></tr><tr>'' from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 20, ''<th>Tabla</th><th>AutoAnalyze</th><th>Analyze</th></tr> <tr><td>'' union select 25, replace(replace(resultado,''|'',''</td><td>&nbsp;''), chr(10), ''</td></tr><tr><td>'') from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 30, ''</td></tr></table>'' union select 40, ''<p><pre>'' union select 50, ''psql -U postgres -c "VACUUM ANALYZE VERBOSE ''|| split_part( unnest( string_to_array( resultados.resultado, chr(10) ) ), ''|'', 1) ||'';" -h ''|| servidores.hostname ||'' -p ''|| servidores.port ||'' -d ''|| resultados.base ||'' & '' from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 60, ''</pre></p>'' union select 70, ''<p>rid: '|| _rid::text ||'</p>'' order by 1 ) tmp ) to program ''mutt   -e "set content_type=text/html" -s "MONITOREO - Problemas de Vacuum Analyze" -- '|| _sdestino ||' '' with (format text);';

    RAISE NOTICE 'SQL: %', _sql;

    EXECUTE _sql;
    RETURN;

END;

$$;


ALTER FUNCTION public.procchildeight_test(_rid integer, _serverid integer, _consultaid integer) OWNER TO postgres;

--
-- Name: procchildfour(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildfour(_rid integer, _serverid integer, _consultaid integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
 _sql text;
DECLARE
 _sdestino text; 
BEGIN

    -- 20170811 DAF Agrego la busqueda de los destinatarios del mail.

    _sdestino := (  select string_agg(valort, ',') as destinos
                    from (
                        select valort
                        from parametros
                        where consulta_id = _consultaid
                        and paramname = 'EMAILTO'
                        and ( 
                            server_id = _serverid
                            or 
                            server_id is null
                            )
                        group by valort
                        ) tmp
                    limit 1 
                 );

    RAISE NOTICE 'Destinatarios: %', _sdestino;

    _sql := 'copy ( select consulta_42(''{'|| _rid::text ||'}'') ) to program ''mutt  -e "set content_type=text/html" -s "MONITOREO - Querys activas mas de 60 minutos" -- '|| _sdestino ||''' with (format text );';

    EXECUTE _sql;

    RETURN;
END;
$$;


ALTER FUNCTION public.procchildfour(_rid integer, _serverid integer, _consultaid integer) OWNER TO postgres;

--
-- Name: procchildone(integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildone(_rid integer, _server_id integer, _resultado text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
            v_query     text;
    DECLARE
          _debug                int;

    BEGIN
            _debug := 1; -- Si 1, debug mode on --
            if _debug = 1 then
                raise notice 'Procesando procchildone rid: % - Sid: % - rdo: %', _rid, _server_id, _resultado;
            End if;

            insert into resdetalle(server_id, valor, detalle_id)
            values ( _server_id , _resultado, (select d.id from detalles d where d.codigo = 'PV')  )
            ON CONFLICT ( server_id, detalle_id ) 
            DO UPDATE SET valor = EXCLUDED.valor, fecha_update = clock_timestamp(), version = EXCLUDED.version + 1 ;

            update public.resultados set estado = 'AZ' where resultados.id = _rid  ;
        
    END;
$$;


ALTER FUNCTION public.procchildone(_rid integer, _server_id integer, _resultado text) OWNER TO postgres;

--
-- Name: procchildten(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildten(_rid integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
 _sql text;

BEGIN
    _sql := 'copy ( select htm from ( select 10, ''<table border="1"><tr><th>Host</th><th>Puerto</th><th>Base</th><th>&nbsp;</th> </tr><tr><td>'' htm union select 15, servidores.hostname || ''</td><td>'' || servidores.port || ''</td><td>'' ||resultados.base || ''</td><td>&nbsp;</td></tr><tr>'' from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 20, ''<th>Schema</th><th>Object</th><th>Owner</th><th>Tipo</th></tr> <tr><td>'' union select 25, replace(replace(resultado,''|'',''</td><td>&nbsp;''), '';;'', ''</td></tr><tr><td>'') from resultados inner join servidores on resultados.server_id = servidores.id where resultados.id = '|| _rid::text ||' union select 30, ''</td></tr></table>'' order by 1 ) tmp ) to program ''mutt   -e "set content_type=text/html" -s "MONITOREO - Problemas de Owners" -- dba@conexia.com'' with (format text);';

    EXECUTE _sql;

    RETURN;
END;
$$;


ALTER FUNCTION public.procchildten(_rid integer) OWNER TO postgres;

--
-- Name: procchildtwelve(integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION procchildtwelve(_ids integer[]) RETURNS TABLE(resultado text)
    LANGUAGE plpgsql SECURITY DEFINER ROWS 100
    AS $$
-- 20180411 DAF Para la salida del caso 46096
begin

	   return query

            select '<table border="1" CELLPADDING="0" CELLSPACING="0"><tr>'::text

            union all
            
            select '<tr><td>' || tmp.rid || '</td><td>' || tmp.serverhostname || '</td><td>' || tmp.serverport || '</td><td>' || tmp.serverfechaharvest || '</td><td>' ||
		tmp.databaseoid || '</td><td>' || tmp.baseconectada || '</td><td>' || tmp.pid || '</td><td>' || tmp.useroid || '</td><td>' ||
		tmp.username || '</td><td>' || tmp.appname || '</td><td>' || tmp.clientaddr || '</td><td>' || tmp.hostname || '</td><td>' ||
		tmp.port || '</td><td>' || tmp.backend_start || '</td><td>' || tmp.fechaultimatrans || '</td><td>' || tmp.fechaultimaconsulta || '</td><td>' ||
		tmp.fechaultimoestado || '</td><td>' || tmp.waiteventbackend || '</td><td>' || tmp.waiteventname || '</td><td>' || tmp.estado || '</td><td>' ||
		tmp.transid || '</td><td>' || tmp.xminhorizon || '</td><td>' || 

		'</tr><tr><th colspan="23">Consulta:</td>'|| '</tr><tr><td colspan="23">'|| tmp.query::text ||'</td></tr>'
		from (

			select  r.id        as rid,  
				s.hostname  as serverhostname, 
				s.port      as serverport, 
				r.fecha     as serverfechaharvest,
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 1)   as databaseoid,         /* datid */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 2)   as baseconectada,       /* datname */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 3)   as pid,                 /* pid */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 4)   as useroid,             /* usesysid */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 5)   as username,            /* usename */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 6)   as appname,             /* application_name */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 7)   as clientaddr,          /* client_addr */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 8)   as hostname,            /* client_hostname */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 9)   as port,                /* client_port */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 10)  as backend_start,       /* backend_start */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 11)  as fechaultimatrans,    /* xact_start */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 12)  as fechaultimaconsulta, /* query_start */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 13)  as fechaultimoestado,   /* state_change */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 14)  as waiteventbackend,    /* wait_event_type */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 15)  as waiteventname,       /* wait_event */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 16)  as estado,              /* state */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 17)  as transid,             /* backend_xid */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 18)  as xminhorizon,         /* backend_xmin */
				split_part(unnest(string_to_array(r.resultado,';;')), '|', 19)::text  as query               /* query */

			FROM public.resultados r
			left join servidores s on s.id = r.server_id
			where r.resultado <> '' and
				r.id in (select unnest(_ids)) and
				--r.id = 42454993 and
				r.consulta_id = 12
		) as tmp
		           
            union all

            select '</table>'::text;

end;
$$;


ALTER FUNCTION public.procchildtwelve(_ids integer[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE acciones (
    id integer NOT NULL,
    descripcion character varying(100) NOT NULL,
    fecha_insert timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE acciones OWNER TO postgres;

--
-- Name: acciones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE acciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE acciones_id_seq OWNER TO postgres;

--
-- Name: acciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE acciones_id_seq OWNED BY acciones.id;


--
-- Name: bases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE bases (
    id integer NOT NULL,
    estado character(2) DEFAULT 'AA'::bpchar NOT NULL,
    server_id integer,
    nombre character varying(50),
    fecha_insert timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE bases OWNER TO postgres;

--
-- Name: bases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE bases_id_seq OWNER TO postgres;

--
-- Name: bases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bases_id_seq OWNED BY bases.id;


--
-- Name: comandos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE comandos (
    id integer NOT NULL,
    estado character(2),
    cmdsid integer,
    consulta character varying(7000),
    base character varying(50),
    descripcion text,
    fecha_insert timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE comandos OWNER TO postgres;

--
-- Name: comandos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE comandos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE comandos_id_seq OWNER TO postgres;

--
-- Name: comandos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE comandos_id_seq OWNED BY comandos.id;


--
-- Name: detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE detalles (
    id integer NOT NULL,
    codigo character(2) NOT NULL,
    valor character varying(1000)
);


ALTER TABLE detalles OWNER TO postgres;

--
-- Name: detalles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE detalles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE detalles_id_seq OWNER TO postgres;

--
-- Name: detalles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE detalles_id_seq OWNED BY detalles.id;


--
-- Name: parametros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE parametros (
    id integer NOT NULL,
    server_id integer,
    consulta_id integer,
    sentido integer,
    valor numeric(10,2),
    valort character varying(100),
    paramname character varying
);


ALTER TABLE parametros OWNER TO postgres;

--
-- Name: parametros_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE parametros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parametros_id_seq OWNER TO postgres;

--
-- Name: parametros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE parametros_id_seq OWNED BY parametros.id;


--
-- Name: resconn; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resconn (
    id integer NOT NULL,
    server_id integer NOT NULL,
    detalle_id integer NOT NULL,
    database_id integer NOT NULL,
    valor character varying(1000) NOT NULL,
    fecha_insert timestamp without time zone DEFAULT now() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE resconn OWNER TO postgres;

--
-- Name: resconn_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resconn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE resconn_id_seq OWNER TO postgres;

--
-- Name: resconn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resconn_id_seq OWNED BY resconn.id;


--
-- Name: resdetalle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resdetalle (
    id integer NOT NULL,
    server_id integer NOT NULL,
    detalle_id integer NOT NULL,
    valor character varying(1000) NOT NULL,
    fecha_insert timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE resdetalle OWNER TO postgres;

--
-- Name: resdetalle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resdetalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE resdetalle_id_seq OWNER TO postgres;

--
-- Name: resdetalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE resdetalle_id_seq OWNED BY resdetalle.id;


--
-- Name: ressize; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize (
    id integer NOT NULL,
    server_id integer NOT NULL,
    detalle_id integer NOT NULL,
    database_id integer NOT NULL,
    valor character varying(1000) NOT NULL,
    fecha_insert timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE ressize OWNER TO postgres;

--
-- Name: ressize_child_2016; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_2016 (
    CONSTRAINT ck_ressize_2016 CHECK ((fecha_insert < '2017-01-01'::date))
)
INHERITS (ressize);


ALTER TABLE ressize_child_2016 OWNER TO postgres;

--
-- Name: ressize_child_201701; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201701 (
    CONSTRAINT ck_ressize_201701 CHECK (((fecha_insert >= '2017-01-01'::date) AND (fecha_insert <= '2017-01-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201701 OWNER TO postgres;

--
-- Name: ressize_child_201702; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201702 (
    CONSTRAINT ck_ressize_201702 CHECK (((fecha_insert >= '2017-02-01'::date) AND (fecha_insert <= '2017-02-28 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201702 OWNER TO postgres;

--
-- Name: ressize_child_201703; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201703 (
    CONSTRAINT ck_ressize_201703 CHECK (((fecha_insert >= '2017-03-01'::date) AND (fecha_insert <= '2017-03-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201703 OWNER TO postgres;

--
-- Name: ressize_child_201704; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201704 (
    CONSTRAINT ck_ressize_201704 CHECK (((fecha_insert >= '2017-04-01'::date) AND (fecha_insert <= '2017-04-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201704 OWNER TO postgres;

--
-- Name: ressize_child_201705; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201705 (
    CONSTRAINT ck_ressize_201705 CHECK (((fecha_insert >= '2017-05-01'::date) AND (fecha_insert <= '2017-05-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201705 OWNER TO postgres;

--
-- Name: ressize_child_201706; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201706 (
    CONSTRAINT ck_ressize_201706 CHECK (((fecha_insert >= '2017-06-01'::date) AND (fecha_insert <= '2017-06-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201706 OWNER TO postgres;

--
-- Name: ressize_child_201707; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201707 (
    CONSTRAINT ck_ressize_201707 CHECK (((fecha_insert >= '2017-07-01'::date) AND (fecha_insert <= '2017-07-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201707 OWNER TO postgres;

--
-- Name: ressize_child_201708; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201708 (
    CONSTRAINT ck_ressize_201708 CHECK (((fecha_insert >= '2017-08-01'::date) AND (fecha_insert <= '2017-08-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201708 OWNER TO postgres;

--
-- Name: ressize_child_201709; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201709 (
    CONSTRAINT ck_ressize_201709 CHECK (((fecha_insert >= '2017-09-01'::date) AND (fecha_insert <= '2017-09-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201709 OWNER TO postgres;

--
-- Name: ressize_child_201710; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201710 (
    CONSTRAINT ck_ressize_201710 CHECK (((fecha_insert >= '2017-10-01'::date) AND (fecha_insert <= '2017-10-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201710 OWNER TO postgres;

--
-- Name: ressize_child_201711; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201711 (
    CONSTRAINT ck_ressize_201711 CHECK (((fecha_insert >= '2017-11-01'::date) AND (fecha_insert <= '2017-11-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201711 OWNER TO postgres;

--
-- Name: ressize_child_201712; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201712 (
    CONSTRAINT ck_ressize_201712 CHECK (((fecha_insert >= '2017-12-01'::date) AND (fecha_insert <= '2017-12-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201712 OWNER TO postgres;

--
-- Name: ressize_child_201801; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201801 (
    CONSTRAINT ck_ressize_201801 CHECK (((fecha_insert >= '2018-01-01'::date) AND (fecha_insert <= '2018-01-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201801 OWNER TO postgres;

--
-- Name: ressize_child_201802; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201802 (
    CONSTRAINT ck_ressize_201802 CHECK (((fecha_insert >= '2018-02-01'::date) AND (fecha_insert <= '2018-02-28 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201802 OWNER TO postgres;

--
-- Name: ressize_child_201803; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201803 (
    CONSTRAINT ck_ressize_201803 CHECK (((fecha_insert >= '2018-03-01'::date) AND (fecha_insert <= '2018-03-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201803 OWNER TO postgres;

--
-- Name: ressize_child_201804; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201804 (
    CONSTRAINT ck_ressize_201804 CHECK (((fecha_insert >= '2018-04-01'::date) AND (fecha_insert <= '2018-04-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201804 OWNER TO postgres;

--
-- Name: ressize_child_201805; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201805 (
    CONSTRAINT ck_ressize_201805 CHECK (((fecha_insert >= '2018-05-01'::date) AND (fecha_insert <= '2018-05-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201805 OWNER TO postgres;

--
-- Name: ressize_child_201806; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201806 (
    CONSTRAINT ck_ressize_201806 CHECK (((fecha_insert >= '2018-06-01'::date) AND (fecha_insert <= '2018-06-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201806 OWNER TO postgres;

--
-- Name: ressize_child_201807; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201807 (
    CONSTRAINT ck_ressize_201807 CHECK (((fecha_insert >= '2018-07-01'::date) AND (fecha_insert <= '2018-07-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201807 OWNER TO postgres;

--
-- Name: ressize_child_201808; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201808 (
    CONSTRAINT ck_ressize_201808 CHECK (((fecha_insert >= '2018-08-01'::date) AND (fecha_insert <= '2018-08-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201808 OWNER TO postgres;

--
-- Name: ressize_child_201809; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201809 (
    CONSTRAINT ck_ressize_201809 CHECK (((fecha_insert >= '2018-09-01'::date) AND (fecha_insert <= '2018-09-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201809 OWNER TO postgres;

--
-- Name: ressize_child_201810; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201810 (
    CONSTRAINT ck_ressize_201810 CHECK (((fecha_insert >= '2018-10-01'::date) AND (fecha_insert <= '2018-10-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201810 OWNER TO postgres;

--
-- Name: ressize_child_201811; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201811 (
    CONSTRAINT ck_ressize_201811 CHECK (((fecha_insert >= '2018-11-01'::date) AND (fecha_insert <= '2018-11-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201811 OWNER TO postgres;

--
-- Name: ressize_child_201812; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201812 (
    CONSTRAINT ck_ressize_201812 CHECK (((fecha_insert >= '2018-12-01'::date) AND (fecha_insert <= '2018-12-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201812 OWNER TO postgres;

--
-- Name: ressize_child_201901; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201901 (
    CONSTRAINT ck_ressize_201901 CHECK (((fecha_insert >= '2019-01-01'::date) AND (fecha_insert <= '2019-01-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201901 OWNER TO postgres;

--
-- Name: ressize_child_201902; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201902 (
    CONSTRAINT ck_ressize_201902 CHECK (((fecha_insert >= '2019-02-01'::date) AND (fecha_insert <= '2019-02-28 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201902 OWNER TO postgres;

--
-- Name: ressize_child_201903; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201903 (
    CONSTRAINT ck_ressize_201903 CHECK (((fecha_insert >= '2019-03-01'::date) AND (fecha_insert <= '2019-03-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201903 OWNER TO postgres;

--
-- Name: ressize_child_201904; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201904 (
    CONSTRAINT ck_ressize_201904 CHECK (((fecha_insert >= '2019-04-01'::date) AND (fecha_insert <= '2019-04-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201904 OWNER TO postgres;

--
-- Name: ressize_child_201905; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201905 (
    CONSTRAINT ck_ressize_201905 CHECK (((fecha_insert >= '2019-05-01'::date) AND (fecha_insert <= '2019-05-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201905 OWNER TO postgres;

--
-- Name: ressize_child_201906; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201906 (
    CONSTRAINT ck_ressize_201906 CHECK (((fecha_insert >= '2019-06-01'::date) AND (fecha_insert <= '2019-06-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201906 OWNER TO postgres;

--
-- Name: ressize_child_201907; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201907 (
    CONSTRAINT ck_ressize_201907 CHECK (((fecha_insert >= '2019-07-01'::date) AND (fecha_insert <= '2019-07-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201907 OWNER TO postgres;

--
-- Name: ressize_child_201908; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201908 (
    CONSTRAINT ck_ressize_201908 CHECK (((fecha_insert >= '2019-08-01'::date) AND (fecha_insert <= '2019-08-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201908 OWNER TO postgres;

--
-- Name: ressize_child_201909; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201909 (
    CONSTRAINT ck_ressize_201909 CHECK (((fecha_insert >= '2019-09-01'::date) AND (fecha_insert <= '2019-09-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201909 OWNER TO postgres;

--
-- Name: ressize_child_201910; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201910 (
    CONSTRAINT ck_ressize_201910 CHECK (((fecha_insert >= '2019-10-01'::date) AND (fecha_insert <= '2019-10-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201910 OWNER TO postgres;

--
-- Name: ressize_child_201911; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201911 (
    CONSTRAINT ck_ressize_201911 CHECK (((fecha_insert >= '2019-11-01'::date) AND (fecha_insert <= '2019-11-30 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201911 OWNER TO postgres;

--
-- Name: ressize_child_201912; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ressize_child_201912 (
    CONSTRAINT ck_ressize_201912 CHECK (((fecha_insert >= '2019-12-01'::date) AND (fecha_insert <= '2019-12-31 00:00:00'::timestamp without time zone)))
)
INHERITS (ressize);


ALTER TABLE ressize_child_201912 OWNER TO postgres;

--
-- Name: ressize_new_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ressize_new_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ressize_new_id_seq OWNER TO postgres;

--
-- Name: ressize_new_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ressize_new_id_seq OWNED BY ressize.id;


--
-- Name: resultados_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE resultados_id_seq
    START WITH 33018102
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE resultados_id_seq OWNER TO postgres;

--
-- Name: resultados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados (
    id integer DEFAULT nextval('resultados_id_seq'::regclass) NOT NULL,
    server_id integer,
    consulta_id integer,
    fecha timestamp without time zone DEFAULT clock_timestamp(),
    resultado text,
    estado character varying(2) NOT NULL,
    base character varying(50)
);


ALTER TABLE resultados OWNER TO postgres;

--
-- Name: resultados_child_0; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_0 (
    CONSTRAINT ck_resultados_0 CHECK ((date_part('hour'::text, fecha) = (0)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_0 OWNER TO postgres;

--
-- Name: resultados_child_1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_1 (
    CONSTRAINT ck_resultados_1 CHECK ((date_part('hour'::text, fecha) = (1)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_1 OWNER TO postgres;

--
-- Name: resultados_child_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_10 (
    CONSTRAINT ck_resultados_10 CHECK ((date_part('hour'::text, fecha) = (10)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_10 OWNER TO postgres;

--
-- Name: resultados_child_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_11 (
    CONSTRAINT ck_resultados_11 CHECK ((date_part('hour'::text, fecha) = (11)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_11 OWNER TO postgres;

--
-- Name: resultados_child_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_12 (
    CONSTRAINT ck_resultados_12 CHECK ((date_part('hour'::text, fecha) = (12)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_12 OWNER TO postgres;

--
-- Name: resultados_child_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_13 (
    CONSTRAINT ck_resultados_13 CHECK ((date_part('hour'::text, fecha) = (13)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_13 OWNER TO postgres;

--
-- Name: resultados_child_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_14 (
    CONSTRAINT ck_resultados_14 CHECK ((date_part('hour'::text, fecha) = (14)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_14 OWNER TO postgres;

--
-- Name: resultados_child_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_15 (
    CONSTRAINT ck_resultados_15 CHECK ((date_part('hour'::text, fecha) = (15)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_15 OWNER TO postgres;

--
-- Name: resultados_child_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_16 (
    CONSTRAINT ck_resultados_16 CHECK ((date_part('hour'::text, fecha) = (16)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_16 OWNER TO postgres;

--
-- Name: resultados_child_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_17 (
    CONSTRAINT ck_resultados_17 CHECK ((date_part('hour'::text, fecha) = (17)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_17 OWNER TO postgres;

--
-- Name: resultados_child_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_18 (
    CONSTRAINT ck_resultados_18 CHECK ((date_part('hour'::text, fecha) = (18)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_18 OWNER TO postgres;

--
-- Name: resultados_child_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_19 (
    CONSTRAINT ck_resultados_19 CHECK ((date_part('hour'::text, fecha) = (19)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_19 OWNER TO postgres;

--
-- Name: resultados_child_2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_2 (
    CONSTRAINT ck_resultados_2 CHECK ((date_part('hour'::text, fecha) = (2)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_2 OWNER TO postgres;

--
-- Name: resultados_child_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_20 (
    CONSTRAINT ck_resultados_20 CHECK ((date_part('hour'::text, fecha) = (20)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_20 OWNER TO postgres;

--
-- Name: resultados_child_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_21 (
    CONSTRAINT ck_resultados_21 CHECK ((date_part('hour'::text, fecha) = (21)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_21 OWNER TO postgres;

--
-- Name: resultados_child_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_22 (
    CONSTRAINT ck_resultados_22 CHECK ((date_part('hour'::text, fecha) = (22)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_22 OWNER TO postgres;

--
-- Name: resultados_child_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_23 (
    CONSTRAINT ck_resultados_23 CHECK ((date_part('hour'::text, fecha) = (23)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_23 OWNER TO postgres;

--
-- Name: resultados_child_24; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_24 (
    CONSTRAINT ck_resultados_24 CHECK ((date_part('hour'::text, fecha) = (24)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_24 OWNER TO postgres;

--
-- Name: resultados_child_3; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_3 (
    CONSTRAINT ck_resultados_3 CHECK ((date_part('hour'::text, fecha) = (3)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_3 OWNER TO postgres;

--
-- Name: resultados_child_4; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_4 (
    CONSTRAINT ck_resultados_4 CHECK ((date_part('hour'::text, fecha) = (4)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_4 OWNER TO postgres;

--
-- Name: resultados_child_5; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_5 (
    CONSTRAINT ck_resultados_5 CHECK ((date_part('hour'::text, fecha) = (5)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_5 OWNER TO postgres;

--
-- Name: resultados_child_6; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_6 (
    CONSTRAINT ck_resultados_6 CHECK ((date_part('hour'::text, fecha) = (6)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_6 OWNER TO postgres;

--
-- Name: resultados_child_7; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_7 (
    CONSTRAINT ck_resultados_7 CHECK ((date_part('hour'::text, fecha) = (7)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_7 OWNER TO postgres;

--
-- Name: resultados_child_8; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_8 (
    CONSTRAINT ck_resultados_8 CHECK ((date_part('hour'::text, fecha) = (8)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_8 OWNER TO postgres;

--
-- Name: resultados_child_9; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE resultados_child_9 (
    CONSTRAINT ck_resultados_9 CHECK ((date_part('hour'::text, fecha) = (9)::double precision))
)
INHERITS (resultados);


ALTER TABLE resultados_child_9 OWNER TO postgres;

--
-- Name: servidores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE servidores (
    id integer NOT NULL,
    estado character(2) NOT NULL,
    hostname character varying(50) NOT NULL,
    port character varying(5) NOT NULL,
    fecha_insert timestamp without time zone DEFAULT now() NOT NULL,
    fecha_update timestamp without time zone,
    fecha_delete timestamp without time zone,
    version integer DEFAULT 1 NOT NULL,
    notas character varying(500),
    pgversion character varying(20)
);


ALTER TABLE servidores OWNER TO postgres;

--
-- Name: servidores_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE servidores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE servidores_id_seq OWNER TO postgres;

--
-- Name: servidores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE servidores_id_seq OWNED BY servidores.id;


--
-- Name: servidores_versiones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE servidores_versiones (
    id integer NOT NULL,
    sid integer NOT NULL,
    pgversion character varying(20) NOT NULL,
    fecha_desde timestamp without time zone DEFAULT now() NOT NULL,
    fecha_hasta timestamp without time zone
);


ALTER TABLE servidores_versiones OWNER TO postgres;

--
-- Name: servidores_versiones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE servidores_versiones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE servidores_versiones_id_seq OWNER TO postgres;

--
-- Name: servidores_versiones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE servidores_versiones_id_seq OWNED BY servidores_versiones.id;


--
-- Name: versiones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE versiones (
    id integer NOT NULL,
    estado character(2),
    valor character varying(6) NOT NULL,
    cmdsid integer DEFAULT 1
);


ALTER TABLE versiones OWNER TO postgres;

--
-- Name: versiones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE versiones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE versiones_id_seq OWNER TO postgres;

--
-- Name: versiones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE versiones_id_seq OWNED BY versiones.id;


--
-- Name: vservidores; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vservidores AS
 SELECT servidores.id,
    servidores.hostname,
    servidores.port
   FROM servidores
  WHERE (servidores.estado = 'AA'::bpchar);


ALTER TABLE vservidores OWNER TO postgres;

--
-- Name: acciones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY acciones ALTER COLUMN id SET DEFAULT nextval('acciones_id_seq'::regclass);


--
-- Name: bases id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bases ALTER COLUMN id SET DEFAULT nextval('bases_id_seq'::regclass);


--
-- Name: comandos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comandos ALTER COLUMN id SET DEFAULT nextval('comandos_id_seq'::regclass);


--
-- Name: detalles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY detalles ALTER COLUMN id SET DEFAULT nextval('detalles_id_seq'::regclass);


--
-- Name: parametros id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parametros ALTER COLUMN id SET DEFAULT nextval('parametros_id_seq'::regclass);


--
-- Name: resconn id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resconn ALTER COLUMN id SET DEFAULT nextval('resconn_id_seq'::regclass);


--
-- Name: resdetalle id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resdetalle ALTER COLUMN id SET DEFAULT nextval('resdetalle_id_seq'::regclass);


--
-- Name: ressize id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_2016 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_2016 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_2016 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_2016 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_2016 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_2016 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201701 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201701 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201701 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201701 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201701 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201701 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201702 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201702 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201702 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201702 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201702 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201702 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201703 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201703 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201703 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201703 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201703 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201703 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201704 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201704 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201704 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201704 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201704 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201704 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201705 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201705 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201705 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201705 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201705 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201705 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201706 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201706 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201706 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201706 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201706 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201706 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201707 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201707 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201707 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201707 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201707 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201707 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201708 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201708 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201708 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201708 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201708 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201708 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201709 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201709 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201709 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201709 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201709 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201709 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201710 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201710 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201710 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201710 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201710 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201710 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201711 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201711 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201711 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201711 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201711 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201711 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201712 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201712 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201712 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201712 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201712 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201712 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201801 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201801 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201801 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201801 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201801 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201801 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201802 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201802 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201802 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201802 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201802 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201802 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201803 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201803 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201803 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201803 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201803 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201803 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201804 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201804 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201804 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201804 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201804 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201804 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201805 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201805 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201805 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201805 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201805 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201805 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201806 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201806 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201806 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201806 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201806 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201806 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201807 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201807 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201807 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201807 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201807 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201807 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201808 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201808 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201808 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201808 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201808 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201808 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201809 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201809 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201809 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201809 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201809 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201809 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201810 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201810 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201810 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201810 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201810 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201810 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201811 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201811 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201811 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201811 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201811 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201811 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201812 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201812 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201812 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201812 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201812 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201812 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201901 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201901 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201901 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201901 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201901 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201901 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201902 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201902 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201902 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201902 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201902 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201902 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201903 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201903 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201903 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201903 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201903 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201903 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201904 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201904 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201904 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201904 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201904 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201904 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201905 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201905 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201905 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201905 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201905 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201905 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201906 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201906 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201906 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201906 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201906 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201906 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201907 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201907 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201907 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201907 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201907 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201907 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201908 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201908 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201908 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201908 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201908 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201908 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201909 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201909 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201909 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201909 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201909 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201909 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201910 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201910 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201910 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201910 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201910 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201910 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201911 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201911 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201911 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201911 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201911 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201911 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: ressize_child_201912 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201912 ALTER COLUMN id SET DEFAULT nextval('ressize_new_id_seq'::regclass);


--
-- Name: ressize_child_201912 fecha_insert; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201912 ALTER COLUMN fecha_insert SET DEFAULT clock_timestamp();


--
-- Name: ressize_child_201912 version; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201912 ALTER COLUMN version SET DEFAULT 1;


--
-- Name: resultados_child_0 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_0 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_0 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_0 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_1 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_1 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_1 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_1 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_10 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_10 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_10 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_10 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_11 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_11 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_11 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_11 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_12 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_12 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_12 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_12 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_13 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_13 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_13 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_13 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_14 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_14 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_14 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_14 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_15 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_15 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_15 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_15 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_16 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_16 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_16 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_16 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_17 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_17 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_17 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_17 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_18 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_18 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_18 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_18 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_19 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_19 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_19 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_19 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_2 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_2 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_2 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_2 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_20 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_20 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_20 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_20 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_21 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_21 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_21 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_21 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_22 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_22 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_22 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_22 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_23 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_23 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_23 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_23 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_24 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_24 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_24 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_24 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_3 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_3 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_3 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_3 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_4 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_4 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_4 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_4 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_5 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_5 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_5 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_5 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_6 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_6 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_6 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_6 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_7 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_7 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_7 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_7 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_8 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_8 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_8 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_8 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: resultados_child_9 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_9 ALTER COLUMN id SET DEFAULT nextval('resultados_id_seq'::regclass);


--
-- Name: resultados_child_9 fecha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_9 ALTER COLUMN fecha SET DEFAULT clock_timestamp();


--
-- Name: servidores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servidores ALTER COLUMN id SET DEFAULT nextval('servidores_id_seq'::regclass);


--
-- Name: servidores_versiones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servidores_versiones ALTER COLUMN id SET DEFAULT nextval('servidores_versiones_id_seq'::regclass);


--
-- Name: versiones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY versiones ALTER COLUMN id SET DEFAULT nextval('versiones_id_seq'::regclass);


--
-- Name: acciones pk_acciones_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY acciones
    ADD CONSTRAINT pk_acciones_id PRIMARY KEY (id);


--
-- Name: bases pk_bases_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bases
    ADD CONSTRAINT pk_bases_id PRIMARY KEY (id);


--
-- Name: comandos pk_comandos_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comandos
    ADD CONSTRAINT pk_comandos_id PRIMARY KEY (id);


--
-- Name: detalles pk_detalles_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY detalles
    ADD CONSTRAINT pk_detalles_codigo PRIMARY KEY (codigo);


--
-- Name: servidores pk_host_port; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servidores
    ADD CONSTRAINT pk_host_port PRIMARY KEY (hostname, port);


--
-- Name: resultados pk_id_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados
    ADD CONSTRAINT pk_id_new PRIMARY KEY (id);


--
-- Name: parametros pk_parametros_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parametros
    ADD CONSTRAINT pk_parametros_id PRIMARY KEY (id);


--
-- Name: resconn pk_resconn_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resconn
    ADD CONSTRAINT pk_resconn_id PRIMARY KEY (id);


--
-- Name: resdetalle pk_resdetalle_server_id_detalle_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resdetalle
    ADD CONSTRAINT pk_resdetalle_server_id_detalle_id PRIMARY KEY (server_id, detalle_id);


--
-- Name: ressize_child_2016 pk_ressize_2016; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_2016
    ADD CONSTRAINT pk_ressize_2016 PRIMARY KEY (id);


--
-- Name: ressize_child_201701 pk_ressize_201701; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201701
    ADD CONSTRAINT pk_ressize_201701 PRIMARY KEY (id);


--
-- Name: ressize_child_201702 pk_ressize_201702; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201702
    ADD CONSTRAINT pk_ressize_201702 PRIMARY KEY (id);


--
-- Name: ressize_child_201703 pk_ressize_201703; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201703
    ADD CONSTRAINT pk_ressize_201703 PRIMARY KEY (id);


--
-- Name: ressize_child_201704 pk_ressize_201704; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201704
    ADD CONSTRAINT pk_ressize_201704 PRIMARY KEY (id);


--
-- Name: ressize_child_201705 pk_ressize_201705; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201705
    ADD CONSTRAINT pk_ressize_201705 PRIMARY KEY (id);


--
-- Name: ressize_child_201706 pk_ressize_201706; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201706
    ADD CONSTRAINT pk_ressize_201706 PRIMARY KEY (id);


--
-- Name: ressize_child_201707 pk_ressize_201707; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201707
    ADD CONSTRAINT pk_ressize_201707 PRIMARY KEY (id);


--
-- Name: ressize_child_201708 pk_ressize_201708; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201708
    ADD CONSTRAINT pk_ressize_201708 PRIMARY KEY (id);


--
-- Name: ressize_child_201709 pk_ressize_201709; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201709
    ADD CONSTRAINT pk_ressize_201709 PRIMARY KEY (id);


--
-- Name: ressize_child_201710 pk_ressize_201710; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201710
    ADD CONSTRAINT pk_ressize_201710 PRIMARY KEY (id);


--
-- Name: ressize_child_201711 pk_ressize_201711; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201711
    ADD CONSTRAINT pk_ressize_201711 PRIMARY KEY (id);


--
-- Name: ressize_child_201712 pk_ressize_201712; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201712
    ADD CONSTRAINT pk_ressize_201712 PRIMARY KEY (id);


--
-- Name: ressize_child_201801 pk_ressize_201801; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201801
    ADD CONSTRAINT pk_ressize_201801 PRIMARY KEY (id);


--
-- Name: ressize_child_201802 pk_ressize_201802; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201802
    ADD CONSTRAINT pk_ressize_201802 PRIMARY KEY (id);


--
-- Name: ressize_child_201803 pk_ressize_201803; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201803
    ADD CONSTRAINT pk_ressize_201803 PRIMARY KEY (id);


--
-- Name: ressize_child_201804 pk_ressize_201804; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201804
    ADD CONSTRAINT pk_ressize_201804 PRIMARY KEY (id);


--
-- Name: ressize_child_201805 pk_ressize_201805; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201805
    ADD CONSTRAINT pk_ressize_201805 PRIMARY KEY (id);


--
-- Name: ressize_child_201806 pk_ressize_201806; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201806
    ADD CONSTRAINT pk_ressize_201806 PRIMARY KEY (id);


--
-- Name: ressize_child_201807 pk_ressize_201807; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201807
    ADD CONSTRAINT pk_ressize_201807 PRIMARY KEY (id);


--
-- Name: ressize_child_201808 pk_ressize_201808; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201808
    ADD CONSTRAINT pk_ressize_201808 PRIMARY KEY (id);


--
-- Name: ressize_child_201809 pk_ressize_201809; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201809
    ADD CONSTRAINT pk_ressize_201809 PRIMARY KEY (id);


--
-- Name: ressize_child_201810 pk_ressize_201810; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201810
    ADD CONSTRAINT pk_ressize_201810 PRIMARY KEY (id);


--
-- Name: ressize_child_201811 pk_ressize_201811; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201811
    ADD CONSTRAINT pk_ressize_201811 PRIMARY KEY (id);


--
-- Name: ressize_child_201812 pk_ressize_201812; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201812
    ADD CONSTRAINT pk_ressize_201812 PRIMARY KEY (id);


--
-- Name: ressize_child_201901 pk_ressize_201901; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201901
    ADD CONSTRAINT pk_ressize_201901 PRIMARY KEY (id);


--
-- Name: ressize_child_201902 pk_ressize_201902; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201902
    ADD CONSTRAINT pk_ressize_201902 PRIMARY KEY (id);


--
-- Name: ressize_child_201903 pk_ressize_201903; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201903
    ADD CONSTRAINT pk_ressize_201903 PRIMARY KEY (id);


--
-- Name: ressize_child_201904 pk_ressize_201904; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201904
    ADD CONSTRAINT pk_ressize_201904 PRIMARY KEY (id);


--
-- Name: ressize_child_201905 pk_ressize_201905; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201905
    ADD CONSTRAINT pk_ressize_201905 PRIMARY KEY (id);


--
-- Name: ressize_child_201906 pk_ressize_201906; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201906
    ADD CONSTRAINT pk_ressize_201906 PRIMARY KEY (id);


--
-- Name: ressize_child_201907 pk_ressize_201907; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201907
    ADD CONSTRAINT pk_ressize_201907 PRIMARY KEY (id);


--
-- Name: ressize_child_201908 pk_ressize_201908; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201908
    ADD CONSTRAINT pk_ressize_201908 PRIMARY KEY (id);


--
-- Name: ressize_child_201909 pk_ressize_201909; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201909
    ADD CONSTRAINT pk_ressize_201909 PRIMARY KEY (id);


--
-- Name: ressize_child_201910 pk_ressize_201910; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201910
    ADD CONSTRAINT pk_ressize_201910 PRIMARY KEY (id);


--
-- Name: ressize_child_201911 pk_ressize_201911; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201911
    ADD CONSTRAINT pk_ressize_201911 PRIMARY KEY (id);


--
-- Name: ressize_child_201912 pk_ressize_201912; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize_child_201912
    ADD CONSTRAINT pk_ressize_201912 PRIMARY KEY (id);


--
-- Name: ressize pk_ressize_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ressize
    ADD CONSTRAINT pk_ressize_id PRIMARY KEY (id);


--
-- Name: resultados_child_0 pk_resultados1_id_0_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_0
    ADD CONSTRAINT pk_resultados1_id_0_new PRIMARY KEY (id);


--
-- Name: resultados_child_10 pk_resultados1_id_10_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_10
    ADD CONSTRAINT pk_resultados1_id_10_new PRIMARY KEY (id);


--
-- Name: resultados_child_11 pk_resultados1_id_11_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_11
    ADD CONSTRAINT pk_resultados1_id_11_new PRIMARY KEY (id);


--
-- Name: resultados_child_12 pk_resultados1_id_12_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_12
    ADD CONSTRAINT pk_resultados1_id_12_new PRIMARY KEY (id);


--
-- Name: resultados_child_13 pk_resultados1_id_13_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_13
    ADD CONSTRAINT pk_resultados1_id_13_new PRIMARY KEY (id);


--
-- Name: resultados_child_14 pk_resultados1_id_14_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_14
    ADD CONSTRAINT pk_resultados1_id_14_new PRIMARY KEY (id);


--
-- Name: resultados_child_15 pk_resultados1_id_15_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_15
    ADD CONSTRAINT pk_resultados1_id_15_new PRIMARY KEY (id);


--
-- Name: resultados_child_16 pk_resultados1_id_16_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_16
    ADD CONSTRAINT pk_resultados1_id_16_new PRIMARY KEY (id);


--
-- Name: resultados_child_17 pk_resultados1_id_17_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_17
    ADD CONSTRAINT pk_resultados1_id_17_new PRIMARY KEY (id);


--
-- Name: resultados_child_18 pk_resultados1_id_18_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_18
    ADD CONSTRAINT pk_resultados1_id_18_new PRIMARY KEY (id);


--
-- Name: resultados_child_19 pk_resultados1_id_19_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_19
    ADD CONSTRAINT pk_resultados1_id_19_new PRIMARY KEY (id);


--
-- Name: resultados_child_1 pk_resultados1_id_1_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_1
    ADD CONSTRAINT pk_resultados1_id_1_new PRIMARY KEY (id);


--
-- Name: resultados_child_20 pk_resultados1_id_20_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_20
    ADD CONSTRAINT pk_resultados1_id_20_new PRIMARY KEY (id);


--
-- Name: resultados_child_21 pk_resultados1_id_21_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_21
    ADD CONSTRAINT pk_resultados1_id_21_new PRIMARY KEY (id);


--
-- Name: resultados_child_22 pk_resultados1_id_22_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_22
    ADD CONSTRAINT pk_resultados1_id_22_new PRIMARY KEY (id);


--
-- Name: resultados_child_23 pk_resultados1_id_23_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_23
    ADD CONSTRAINT pk_resultados1_id_23_new PRIMARY KEY (id);


--
-- Name: resultados_child_24 pk_resultados1_id_24_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_24
    ADD CONSTRAINT pk_resultados1_id_24_new PRIMARY KEY (id);


--
-- Name: resultados_child_2 pk_resultados1_id_2_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_2
    ADD CONSTRAINT pk_resultados1_id_2_new PRIMARY KEY (id);


--
-- Name: resultados_child_3 pk_resultados1_id_3_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_3
    ADD CONSTRAINT pk_resultados1_id_3_new PRIMARY KEY (id);


--
-- Name: resultados_child_4 pk_resultados1_id_4_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_4
    ADD CONSTRAINT pk_resultados1_id_4_new PRIMARY KEY (id);


--
-- Name: resultados_child_5 pk_resultados1_id_5_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_5
    ADD CONSTRAINT pk_resultados1_id_5_new PRIMARY KEY (id);


--
-- Name: resultados_child_6 pk_resultados1_id_6_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_6
    ADD CONSTRAINT pk_resultados1_id_6_new PRIMARY KEY (id);


--
-- Name: resultados_child_7 pk_resultados1_id_7_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_7
    ADD CONSTRAINT pk_resultados1_id_7_new PRIMARY KEY (id);


--
-- Name: resultados_child_8 pk_resultados1_id_8_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_8
    ADD CONSTRAINT pk_resultados1_id_8_new PRIMARY KEY (id);


--
-- Name: resultados_child_9 pk_resultados1_id_9_new; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY resultados_child_9
    ADD CONSTRAINT pk_resultados1_id_9_new PRIMARY KEY (id);


--
-- Name: versiones pk_valor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY versiones
    ADD CONSTRAINT pk_valor PRIMARY KEY (valor);


--
-- Name: servidores_versiones servidores_versiones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servidores_versiones
    ADD CONSTRAINT servidores_versiones_pkey PRIMARY KEY (id);


--
-- Name: bases uq_bases_server_id_base; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bases
    ADD CONSTRAINT uq_bases_server_id_base UNIQUE (server_id, nombre);


--
-- Name: idx_ressize_child_2016; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ressize_child_2016 ON ressize_child_2016 USING btree (fecha_insert);


--
-- Name: idx_resultados_0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_0 ON resultados_child_0 USING btree (fecha);


--
-- Name: idx_resultados_1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_1 ON resultados_child_1 USING btree (fecha);


--
-- Name: idx_resultados_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_10 ON resultados_child_10 USING btree (fecha);


--
-- Name: idx_resultados_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_11 ON resultados_child_11 USING btree (fecha);


--
-- Name: idx_resultados_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_12 ON resultados_child_12 USING btree (fecha);


--
-- Name: idx_resultados_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_13 ON resultados_child_13 USING btree (fecha);


--
-- Name: idx_resultados_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_14 ON resultados_child_14 USING btree (fecha);


--
-- Name: idx_resultados_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_15 ON resultados_child_15 USING btree (fecha);


--
-- Name: idx_resultados_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_17 ON resultados_child_17 USING btree (fecha);


--
-- Name: idx_resultados_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_18 ON resultados_child_18 USING btree (fecha);


--
-- Name: idx_resultados_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_19 ON resultados_child_19 USING btree (fecha);


--
-- Name: idx_resultados_2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_2 ON resultados_child_2 USING btree (fecha);


--
-- Name: idx_resultados_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_20 ON resultados_child_20 USING btree (fecha);


--
-- Name: idx_resultados_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_21 ON resultados_child_21 USING btree (fecha);


--
-- Name: idx_resultados_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_22 ON resultados_child_22 USING btree (fecha);


--
-- Name: idx_resultados_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_23 ON resultados_child_23 USING btree (fecha);


--
-- Name: idx_resultados_24; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_24 ON resultados_child_24 USING btree (fecha);


--
-- Name: idx_resultados_3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_3 ON resultados_child_3 USING btree (fecha);


--
-- Name: idx_resultados_4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_4 ON resultados_child_4 USING btree (fecha);


--
-- Name: idx_resultados_5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_5 ON resultados_child_5 USING btree (fecha);


--
-- Name: idx_resultados_6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_6 ON resultados_child_6 USING btree (fecha);


--
-- Name: idx_resultados_7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_7 ON resultados_child_7 USING btree (fecha);


--
-- Name: idx_resultados_8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_8 ON resultados_child_8 USING btree (fecha);


--
-- Name: idx_resultados_9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resultados_9 ON resultados_child_9 USING btree (fecha);


--
-- Name: ix_bases_nombre_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_bases_nombre_server_id ON bases USING btree (nombre, server_id);


--
-- Name: ix_resconn_base_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_resconn_base_server_id ON resconn USING btree (database_id, detalle_id, server_id);


--
-- Name: ix_ressize_child_2016_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_2016_server_id ON ressize_child_2016 USING btree (server_id);


--
-- Name: ix_ressize_child_201701_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201701_database_id ON ressize_child_201701 USING btree (database_id);


--
-- Name: ix_ressize_child_201701_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201701_detalle_id ON ressize_child_201701 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201701_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201701_fecha_delete ON ressize_child_201701 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201701_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201701_server_id ON ressize_child_201701 USING btree (server_id);


--
-- Name: ix_ressize_child_201702_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201702_database_id ON ressize_child_201702 USING btree (database_id);


--
-- Name: ix_ressize_child_201702_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201702_detalle_id ON ressize_child_201702 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201702_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201702_fecha_delete ON ressize_child_201702 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201702_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201702_server_id ON ressize_child_201702 USING btree (server_id);


--
-- Name: ix_ressize_child_201703_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201703_database_id ON ressize_child_201703 USING btree (database_id);


--
-- Name: ix_ressize_child_201703_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201703_detalle_id ON ressize_child_201703 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201703_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201703_fecha_delete ON ressize_child_201703 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201703_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201703_server_id ON ressize_child_201703 USING btree (server_id);


--
-- Name: ix_ressize_child_201704_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201704_database_id ON ressize_child_201704 USING btree (database_id);


--
-- Name: ix_ressize_child_201704_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201704_detalle_id ON ressize_child_201704 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201704_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201704_fecha_delete ON ressize_child_201704 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201704_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201704_server_id ON ressize_child_201704 USING btree (server_id);


--
-- Name: ix_ressize_child_201705_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201705_database_id ON ressize_child_201705 USING btree (database_id);


--
-- Name: ix_ressize_child_201705_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201705_detalle_id ON ressize_child_201705 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201705_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201705_fecha_delete ON ressize_child_201705 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201705_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201705_server_id ON ressize_child_201705 USING btree (server_id);


--
-- Name: ix_ressize_child_201706_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201706_database_id ON ressize_child_201706 USING btree (database_id);


--
-- Name: ix_ressize_child_201706_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201706_detalle_id ON ressize_child_201706 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201706_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201706_fecha_delete ON ressize_child_201706 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201706_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201706_server_id ON ressize_child_201706 USING btree (server_id);


--
-- Name: ix_ressize_child_201707_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201707_database_id ON ressize_child_201707 USING btree (database_id);


--
-- Name: ix_ressize_child_201707_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201707_detalle_id ON ressize_child_201707 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201707_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201707_fecha_delete ON ressize_child_201707 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201707_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201707_server_id ON ressize_child_201707 USING btree (server_id);


--
-- Name: ix_ressize_child_201708_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201708_database_id ON ressize_child_201708 USING btree (database_id);


--
-- Name: ix_ressize_child_201708_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201708_detalle_id ON ressize_child_201708 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201708_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201708_fecha_delete ON ressize_child_201708 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201708_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201708_server_id ON ressize_child_201708 USING btree (server_id);


--
-- Name: ix_ressize_child_201709_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201709_database_id ON ressize_child_201709 USING btree (database_id);


--
-- Name: ix_ressize_child_201709_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201709_detalle_id ON ressize_child_201709 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201709_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201709_fecha_delete ON ressize_child_201709 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201709_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201709_server_id ON ressize_child_201709 USING btree (server_id);


--
-- Name: ix_ressize_child_201710_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201710_database_id ON ressize_child_201710 USING btree (database_id);


--
-- Name: ix_ressize_child_201710_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201710_detalle_id ON ressize_child_201710 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201710_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201710_fecha_delete ON ressize_child_201710 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201710_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201710_server_id ON ressize_child_201710 USING btree (server_id);


--
-- Name: ix_ressize_child_201711_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201711_database_id ON ressize_child_201711 USING btree (database_id);


--
-- Name: ix_ressize_child_201711_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201711_detalle_id ON ressize_child_201711 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201711_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201711_fecha_delete ON ressize_child_201711 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201711_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201711_server_id ON ressize_child_201711 USING btree (server_id);


--
-- Name: ix_ressize_child_201712_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201712_database_id ON ressize_child_201712 USING btree (database_id);


--
-- Name: ix_ressize_child_201712_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201712_detalle_id ON ressize_child_201712 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201712_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201712_fecha_delete ON ressize_child_201712 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201712_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201712_server_id ON ressize_child_201712 USING btree (server_id);


--
-- Name: ix_ressize_child_201801_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201801_database_id ON ressize_child_201801 USING btree (database_id);


--
-- Name: ix_ressize_child_201801_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201801_detalle_id ON ressize_child_201801 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201801_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201801_fecha_delete ON ressize_child_201801 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201801_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201801_server_id ON ressize_child_201801 USING btree (server_id);


--
-- Name: ix_ressize_child_201802_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201802_database_id ON ressize_child_201802 USING btree (database_id);


--
-- Name: ix_ressize_child_201802_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201802_detalle_id ON ressize_child_201802 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201802_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201802_fecha_delete ON ressize_child_201802 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201802_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201802_server_id ON ressize_child_201802 USING btree (server_id);


--
-- Name: ix_ressize_child_201803_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201803_database_id ON ressize_child_201803 USING btree (database_id);


--
-- Name: ix_ressize_child_201803_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201803_detalle_id ON ressize_child_201803 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201803_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201803_fecha_delete ON ressize_child_201803 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201803_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201803_server_id ON ressize_child_201803 USING btree (server_id);


--
-- Name: ix_ressize_child_201804_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201804_database_id ON ressize_child_201804 USING btree (database_id);


--
-- Name: ix_ressize_child_201804_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201804_detalle_id ON ressize_child_201804 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201804_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201804_fecha_delete ON ressize_child_201804 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201804_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201804_server_id ON ressize_child_201804 USING btree (server_id);


--
-- Name: ix_ressize_child_201805_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201805_database_id ON ressize_child_201805 USING btree (database_id);


--
-- Name: ix_ressize_child_201805_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201805_detalle_id ON ressize_child_201805 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201805_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201805_fecha_delete ON ressize_child_201805 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201805_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201805_server_id ON ressize_child_201805 USING btree (server_id);


--
-- Name: ix_ressize_child_201806_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201806_database_id ON ressize_child_201806 USING btree (database_id);


--
-- Name: ix_ressize_child_201806_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201806_detalle_id ON ressize_child_201806 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201806_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201806_fecha_delete ON ressize_child_201806 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201806_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201806_server_id ON ressize_child_201806 USING btree (server_id);


--
-- Name: ix_ressize_child_201807_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201807_database_id ON ressize_child_201807 USING btree (database_id);


--
-- Name: ix_ressize_child_201807_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201807_detalle_id ON ressize_child_201807 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201807_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201807_fecha_delete ON ressize_child_201807 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201807_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201807_server_id ON ressize_child_201807 USING btree (server_id);


--
-- Name: ix_ressize_child_201808_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201808_database_id ON ressize_child_201808 USING btree (database_id);


--
-- Name: ix_ressize_child_201808_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201808_detalle_id ON ressize_child_201808 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201808_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201808_fecha_delete ON ressize_child_201808 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201808_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201808_server_id ON ressize_child_201808 USING btree (server_id);


--
-- Name: ix_ressize_child_201809_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201809_database_id ON ressize_child_201809 USING btree (database_id);


--
-- Name: ix_ressize_child_201809_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201809_detalle_id ON ressize_child_201809 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201809_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201809_fecha_delete ON ressize_child_201809 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201809_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201809_server_id ON ressize_child_201809 USING btree (server_id);


--
-- Name: ix_ressize_child_201810_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201810_database_id ON ressize_child_201810 USING btree (database_id);


--
-- Name: ix_ressize_child_201810_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201810_detalle_id ON ressize_child_201810 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201810_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201810_fecha_delete ON ressize_child_201810 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201810_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201810_server_id ON ressize_child_201810 USING btree (server_id);


--
-- Name: ix_ressize_child_201811_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201811_database_id ON ressize_child_201811 USING btree (database_id);


--
-- Name: ix_ressize_child_201811_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201811_detalle_id ON ressize_child_201811 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201811_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201811_fecha_delete ON ressize_child_201811 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201811_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201811_server_id ON ressize_child_201811 USING btree (server_id);


--
-- Name: ix_ressize_child_201812_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201812_database_id ON ressize_child_201812 USING btree (database_id);


--
-- Name: ix_ressize_child_201812_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201812_detalle_id ON ressize_child_201812 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201812_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201812_fecha_delete ON ressize_child_201812 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201812_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201812_server_id ON ressize_child_201812 USING btree (server_id);


--
-- Name: ix_ressize_child_201901_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201901_database_id ON ressize_child_201901 USING btree (database_id);


--
-- Name: ix_ressize_child_201901_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201901_detalle_id ON ressize_child_201901 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201901_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201901_fecha_delete ON ressize_child_201901 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201901_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201901_server_id ON ressize_child_201901 USING btree (server_id);


--
-- Name: ix_ressize_child_201902_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201902_database_id ON ressize_child_201902 USING btree (database_id);


--
-- Name: ix_ressize_child_201902_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201902_detalle_id ON ressize_child_201902 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201902_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201902_fecha_delete ON ressize_child_201902 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201902_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201902_server_id ON ressize_child_201902 USING btree (server_id);


--
-- Name: ix_ressize_child_201903_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201903_database_id ON ressize_child_201903 USING btree (database_id);


--
-- Name: ix_ressize_child_201903_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201903_detalle_id ON ressize_child_201903 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201903_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201903_fecha_delete ON ressize_child_201903 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201903_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201903_server_id ON ressize_child_201903 USING btree (server_id);


--
-- Name: ix_ressize_child_201904_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201904_database_id ON ressize_child_201904 USING btree (database_id);


--
-- Name: ix_ressize_child_201904_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201904_detalle_id ON ressize_child_201904 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201904_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201904_fecha_delete ON ressize_child_201904 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201904_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201904_server_id ON ressize_child_201904 USING btree (server_id);


--
-- Name: ix_ressize_child_201905_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201905_database_id ON ressize_child_201905 USING btree (database_id);


--
-- Name: ix_ressize_child_201905_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201905_detalle_id ON ressize_child_201905 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201905_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201905_fecha_delete ON ressize_child_201905 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201905_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201905_server_id ON ressize_child_201905 USING btree (server_id);


--
-- Name: ix_ressize_child_201906_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201906_database_id ON ressize_child_201906 USING btree (database_id);


--
-- Name: ix_ressize_child_201906_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201906_detalle_id ON ressize_child_201906 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201906_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201906_fecha_delete ON ressize_child_201906 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201906_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201906_server_id ON ressize_child_201906 USING btree (server_id);


--
-- Name: ix_ressize_child_201907_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201907_database_id ON ressize_child_201907 USING btree (database_id);


--
-- Name: ix_ressize_child_201907_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201907_detalle_id ON ressize_child_201907 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201907_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201907_fecha_delete ON ressize_child_201907 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201907_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201907_server_id ON ressize_child_201907 USING btree (server_id);


--
-- Name: ix_ressize_child_201908_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201908_database_id ON ressize_child_201908 USING btree (database_id);


--
-- Name: ix_ressize_child_201908_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201908_detalle_id ON ressize_child_201908 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201908_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201908_fecha_delete ON ressize_child_201908 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201908_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201908_server_id ON ressize_child_201908 USING btree (server_id);


--
-- Name: ix_ressize_child_201909_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201909_database_id ON ressize_child_201909 USING btree (database_id);


--
-- Name: ix_ressize_child_201909_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201909_detalle_id ON ressize_child_201909 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201909_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201909_fecha_delete ON ressize_child_201909 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201909_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201909_server_id ON ressize_child_201909 USING btree (server_id);


--
-- Name: ix_ressize_child_201910_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201910_database_id ON ressize_child_201910 USING btree (database_id);


--
-- Name: ix_ressize_child_201910_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201910_detalle_id ON ressize_child_201910 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201910_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201910_fecha_delete ON ressize_child_201910 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201910_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201910_server_id ON ressize_child_201910 USING btree (server_id);


--
-- Name: ix_ressize_child_201911_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201911_database_id ON ressize_child_201911 USING btree (database_id);


--
-- Name: ix_ressize_child_201911_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201911_detalle_id ON ressize_child_201911 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201911_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201911_fecha_delete ON ressize_child_201911 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201911_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201911_server_id ON ressize_child_201911 USING btree (server_id);


--
-- Name: ix_ressize_child_201912_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201912_database_id ON ressize_child_201912 USING btree (database_id);


--
-- Name: ix_ressize_child_201912_detalle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201912_detalle_id ON ressize_child_201912 USING btree (detalle_id);


--
-- Name: ix_ressize_child_201912_fecha_delete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201912_fecha_delete ON ressize_child_201912 USING btree (fecha_delete NULLS FIRST);


--
-- Name: ix_ressize_child_201912_server_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_child_201912_server_id ON ressize_child_201912 USING btree (server_id);


--
-- Name: ix_ressize_server_id_database_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ressize_server_id_database_id ON ressize USING btree (server_id, database_id, fecha_insert NULLS FIRST);


--
-- Name: ix_resultados_fecha_2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_resultados_fecha_2 ON resultados USING btree (fecha);


--
-- Name: resultados tr_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_insert BEFORE INSERT ON resultados FOR EACH ROW EXECUTE PROCEDURE fn_insert();


--
-- Name: ressize tr_ressize_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_ressize_insert BEFORE INSERT ON ressize FOR EACH ROW EXECUTE PROCEDURE fn_ressize_insert();


SET search_path = pgbouncer, pg_catalog;

--
-- Name: get_auth(text); Type: ACL; Schema: pgbouncer; Owner: postgres
--

REVOKE ALL ON FUNCTION get_auth(p_usename text) FROM PUBLIC;
GRANT ALL ON FUNCTION get_auth(p_usename text) TO grupo_lectura;
GRANT ALL ON FUNCTION get_auth(p_usename text) TO pgbouncer;


--
-- PostgreSQL database dump complete
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 10.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

