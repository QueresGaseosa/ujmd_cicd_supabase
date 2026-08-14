-- =============================================================================
-- UNIVERSIDAD DR. JOSÉ MATÍAS DELGADO (UJMD)
-- Carrera: Licenciatura en Innovación y Transformación Digital
-- Asignatura: Arquitectura de Datos en Entornos Digitales
-- Semana 2: Script DDL PostgreSQL - Caso "Sivar Express" (Modelo 3FN)
-- =============================================================================

-- 1. LIMPIEZA DE TABLAS (Drop en orden inverso por dependencias de FK)
DROP TABLE IF EXISTS detalle_pedido CASCADE;
DROP TABLE IF EXISTS pedido CASCADE;
DROP TABLE IF EXISTS producto CASCADE;
DROP TABLE IF EXISTS repartidor CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;
DROP TABLE IF EXISTS municipio CASCADE;
DROP TABLE IF EXISTS departamento CASCADE;

-- =============================================================================
-- 2. CREACIÓN DE TABLAS (DDL)
-- =============================================================================

-- Tabla: DEPARTAMENTO (Aislamiento de dependencias transitivas - 3FN)
CREATE TABLE departamento (
    id_departamento SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

COMMENT ON TABLE departamento IS 'Catálogo de departamentos de El Salvador';

-- Tabla: MUNICIPIO
CREATE TABLE municipio (
    id_municipio SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_departamento INT NOT NULL,
    CONSTRAINT fk_municipio_departamento FOREIGN KEY (id_departamento)
        REFERENCES departamento(id_departamento) ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE municipio IS 'Catálogo de municipios vinculados a departamento';

-- Tabla: CLIENTE
CREATE TABLE cliente (
    dui_cliente VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    direccion_linea1 VARCHAR(255) NOT NULL,
    id_municipio INT NOT NULL,
    CONSTRAINT chk_dui_formato CHECK (dui_cliente ~ '^[0-9]{8}-[0-9]{1}$'),
    CONSTRAINT fk_cliente_municipio FOREIGN KEY (id_municipio)
        REFERENCES municipio(id_municipio) ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE cliente IS 'Registro de clientes con dirección normalizada';

-- Tabla: REPARTIDOR
CREATE TABLE repartidor (
    id_repartidor VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    placa_vehiculo VARCHAR(15) NOT NULL,
    tipo_vehiculo VARCHAR(30) NOT NULL CHECK (tipo_vehiculo IN ('Motocicleta', 'Automóvil', 'Bicicleta', 'Panel'))
);

COMMENT ON TABLE repartidor IS 'Personal de entrega y sus vehículos asignados';

-- Tabla: PRODUCTO
CREATE TABLE producto (
    id_producto VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio_actual NUMERIC(10,2) NOT NULL CHECK (precio_actual >= 0)
);

COMMENT ON TABLE producto IS 'Catálogo maestro de productos y precio vigente';

-- Tabla: PEDIDO (Cabecera del Pedido)
CREATE TABLE pedido (
    id_pedido INT PRIMARY KEY,
    fecha_hora TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dui_cliente VARCHAR(10) NOT NULL,
    id_repartidor VARCHAR(10) NOT NULL,
    costo_envio NUMERIC(10,2) NOT NULL CHECK (costo_envio >= 0),
    metodo_pago VARCHAR(30) NOT NULL CHECK (metodo_pago IN ('Efectivo', 'Tarjeta de Crédito', 'Tarjeta de Débito', 'Transferencia')),
    estado_pedido VARCHAR(30) NOT NULL CHECK (estado_pedido IN ('Pendiente', 'En Camino', 'Entregado', 'Cancelado')),
    sucursal_origen VARCHAR(150) NOT NULL,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (dui_cliente)
        REFERENCES cliente(dui_cliente) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_repartidor FOREIGN KEY (id_repartidor)
        REFERENCES repartidor(id_repartidor) ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE pedido IS 'Cabecera de pedidos realizados por los clientes';

-- Tabla: DETALLE_PEDIDO (Tabla Asociativa N:M que resuelve Pedido <-> Producto)
CREATE TABLE detalle_pedido (
    id_detalle SERIAL PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto VARCHAR(10) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_historico NUMERIC(10,2) NOT NULL CHECK (precio_unitario_historico >= 0),
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_pedido_producto UNIQUE (id_pedido, id_producto)
);

COMMENT ON TABLE detalle_pedido IS 'Desglose de productos por pedido con precio histórico congelado';

-- =============================================================================
-- 3. INSERCIÓN DE DATOS DE PRUEBA (DML)
-- =============================================================================

INSERT INTO departamento (nombre) VALUES ('San Salvador'), ('La Libertad');

INSERT INTO municipio (nombre, id_departamento) VALUES 
('San Salvador', 1),
('Antiguo Cuscatlán', 2),
('Santa Tecla', 2);

INSERT INTO cliente (dui_cliente, nombre, telefono, direccion_linea1, id_municipio) VALUES 
('05123456-7', 'María Carmen Benítez', '7890-1234', 'Col. Escalón, Pasaje 3, #12', 1),
('06112233-4', 'José Roberto Gómez', '7123-4567', 'Av. Las Palmas #45', 2);

INSERT INTO repartidor (id_repartidor, nombre, placa_vehiculo, tipo_vehiculo) VALUES 
('REP-88', 'Carlos Eduardo Rivas', 'M-567890', 'Motocicleta'),
('REP-42', 'Ana Sofía Martínez', 'M-112233', 'Motocicleta');

INSERT INTO producto (id_producto, nombre, precio_actual) VALUES 
('PROD-01', 'Pupusas Revueltas', 1.25),
('PROD-08', 'Horchata 500ml', 2.00),
('PROD-12', 'Empanadas de Leche x3', 2.50);

INSERT INTO pedido (id_pedido, fecha_hora, dui_cliente, id_repartidor, costo_envio, metodo_pago, estado_pedido, sucursal_origen) VALUES 
(1001, '2026-07-26 18:30:00', '05123456-7', 'REP-88', 2.50, 'Tarjeta de Crédito', 'Entregado', 'Pupusería La Bendición - Sucursal Escalón'),
(1002, '2026-07-26 19:15:00', '06112233-4', 'REP-42', 3.00, 'Efectivo', 'Entregado', 'Pupusería La Bendición - Sucursal Antiguo');

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario_historico) VALUES 
(1001, 'PROD-01', 4, 1.25),
(1001, 'PROD-08', 2, 2.00),
(1002, 'PROD-01', 6, 1.25),
(1002, 'PROD-12', 2, 2.50);