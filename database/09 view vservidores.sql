CREATE OR REPLACE VIEW public.vservidores AS 
 SELECT servidores.id,
    servidores.hostname,
    servidores.port
   FROM servidores
  WHERE servidores.estado = 'AA'::bpchar;