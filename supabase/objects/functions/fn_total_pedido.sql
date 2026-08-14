-- =========================================================
-- FUNCIÓN: fn_total_pedido
-- Calcula el total de un pedido
-- =========================================================

CREATE OR REPLACE FUNCTION fn_total_pedido(
    p_id_pedido INT
)
RETURNS NUMERIC(12,2)
LANGUAGE SQL
AS $$
    SELECT
        COALESCE(
            SUM(
                dp.cantidad * dp.precio_unitario_historico
            ),
            0
        )
        + pe.costo_envio

    FROM pedido pe

    LEFT JOIN detalle_pedido dp
        ON pe.id_pedido = dp.id_pedido

    WHERE pe.id_pedido = p_id_pedido

    GROUP BY pe.costo_envio;
$$;
SELECT fn_total_pedido(1001);