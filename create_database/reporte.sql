-- Reporte esperado:
-- id_pedido, cliente, direccion, repartidor, subtotal, envio, total cobrado

SELECT pe.id_pedido
        , cl.dui_cliente DUI 
        , cl.nombre, 
        (cl.direccion_linea1||', '||dep.nombre||', '||mun.nombre) as direccion
FROM pedido pe
    , cliente cl
    , departamento dep
    , municipio mun
where pe.dui_cliente = cl.dui_cliente
and cl.id_municipio = mun.id_municipio
and mun.id_departamento = dep.id_departamento


select * from pedido

select * from cliente

select * from departamento

select mun.nombre nombre_municipio, dep.nombre nombre_departamento
from municipio mun, departamento dep
where mun.id_departamento = dep.id_departamento