-- ==========================================================
-- Migration: agrega email a cliente
-- ==========================================================

ALTER TABLE cliente
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

COMMENT ON COLUMN cliente.email
IS 'Correo electronico de contacto del cliente (opcional)';