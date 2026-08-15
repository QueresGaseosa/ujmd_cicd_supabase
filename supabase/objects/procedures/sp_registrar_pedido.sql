-- ==========================================================
-- Stored Procedure: sp_registrar_pedido
-- Descripcion: Registra un nuevo pedido con sus detalles
--              de forma atomica (todo o nada)
-- Archivo: supabase/objects/procedures/sp_registrar_pedido.sql
-- ESTE ARCHIVO SE EDITA DIRECTAMENTE - no crear nuevas versiones
-- ==========================================================

CREATE OR REPLACE PROCEDURE sp_registrar_pedido(
    p_dui_cliente     VARCHAR(10),
    p_id_repartidor   VARCHAR(10),
    p_costo_envio     NUMERIC(10,2),
    p_metodo_pago     VARCHAR(30),
    p_sucursal_origen VARCHAR(150),
    p_detalles        JSONB
    -- Array: [{"id_producto": "PROD-01", "cantidad": 2, "precio_unitario_historico": 1.25}]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_pedido INT;
    v_detalle   JSONB;
    v_total     NUMERIC(10,2) := 0;
    v_existe    BOOLEAN;
BEGIN
    -- Validar que el cliente exista
    SELECT EXISTS (
        SELECT 1
        FROM cliente
        WHERE dui_cliente = p_dui_cliente
    ) INTO v_existe;

    IF NOT v_existe THEN
        RAISE EXCEPTION 'Cliente con DUI % no existe', p_dui_cliente;
    END IF;

    -- id_pedido no es SERIAL en esta tabla, se calcula manualmente.
    -- Nota: MAX+1 no es seguro bajo alta concurrencia; para produccion real
    -- se recomendaria una SEQUENCE dedicada. Suficiente para este laboratorio.
    SELECT COALESCE(MAX(id_pedido), 1000) + 1
    INTO v_id_pedido
    FROM pedido;

    -- 1. Insertar el pedido principal
    INSERT INTO pedido (
        id_pedido,
        dui_cliente,
        id_repartidor,
        costo_envio,
        metodo_pago,
        estado_pedido,
        sucursal_origen
    )
    VALUES (
        v_id_pedido,
        p_dui_cliente,
        p_id_repartidor,
        p_costo_envio,
        p_metodo_pago,
        'Pendiente',
        p_sucursal_origen
    );

    -- 2. Insertar cada linea de detalle
    FOR v_detalle IN
        SELECT * FROM jsonb_array_elements(p_detalles)
    LOOP
        INSERT INTO detalle_pedido (
            id_pedido,
            id_producto,
            cantidad,
            precio_unitario_historico
        )
        VALUES (
            v_id_pedido,
            v_detalle->>'id_producto',
            (v_detalle->>'cantidad')::INT,
            (v_detalle->>'precio_unitario_historico')::NUMERIC
        );

        v_total := v_total +
            (v_detalle->>'cantidad')::INT *
            (v_detalle->>'precio_unitario_historico')::NUMERIC;
    END LOOP;

    RAISE NOTICE
        'Pedido % registrado. Total productos: %. Costo envio: %',
        v_id_pedido,
        v_total,
        p_costo_envio;
END;
$$;