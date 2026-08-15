-- =========================================================
-- VISTA: resumen_pedidos
-- Caso Sivar Express
-- =========================================================

CREATE OR REPLACE VIEW resumen_pedidos AS

SELECT
    pe.id_pedido,
    pe.fecha_hora,
    cl.dui_cliente,
    cl.nombre AS cliente,

    cl.direccion_linea1
        || ', '
        || mun.nombre
        || ', '
        || dep.nombre AS direccion,

    re.nombre AS repartidor,
    pe.estado_pedido,
    pe.metodo_pago,
    pe.costo_envio,

    SUM(
        dp.cantidad * dp.precio_unitario_historico
    ) AS subtotal,

    SUM(
        dp.cantidad * dp.precio_unitario_historico
    ) + pe.costo_envio AS total_cobrado

FROM pedido pe

JOIN cliente cl
    ON pe.dui_cliente = cl.dui_cliente

JOIN municipio mun
    ON cl.id_municipio = mun.id_municipio

JOIN departamento dep
    ON mun.id_departamento = dep.id_departamento

JOIN repartidor re
    ON pe.id_repartidor = re.id_repartidor

JOIN detalle_pedido dp
    ON pe.id_pedido = dp.id_pedido

GROUP BY
    pe.id_pedido,
    pe.fecha_hora,
    cl.dui_cliente,
    cl.nombre,
    cl.direccion_linea1,
    mun.nombre,
    dep.nombre,
    re.nombre,
    pe.estado_pedido,
    pe.metodo_pago,
    pe.costo_envio;