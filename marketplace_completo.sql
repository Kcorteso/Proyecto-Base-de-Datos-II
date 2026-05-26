-- =====================================================
-- MARKETPLACE DATABASE
-- =====================================================
-- Descripción: Base de datos para un sistema de
--              marketplace con usuarios, productos,
--              órdenes, envíos y pagos.
-- Autor:      Daniel y Rafael
-- Fecha:       2026
-- =====================================================


-- =========================
-- TABLAS
-- =========================

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(150),
    rol VARCHAR(20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE producto (
    id_producto SERIAL PRIMARY KEY,
    id_vendedor INT,
    nombre VARCHAR(120),
    categoria VARCHAR(80),
    precio NUMERIC(12,2),
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_vendedor) REFERENCES usuario(id_usuario)
);

CREATE TABLE inventario (
    id_inventario SERIAL PRIMARY KEY,
    id_producto INT UNIQUE,
    stock_actual INT,
    stock_minimo INT,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE orden (
    id_orden SERIAL PRIMARY KEY,
    id_comprador INT,
    id_vendedor INT,
    fecha_orden TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20),
    FOREIGN KEY (id_comprador) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_vendedor) REFERENCES usuario(id_usuario)
);

CREATE TABLE detalle_orden (
    id_detalle SERIAL PRIMARY KEY,
    id_orden INT,
    id_producto INT,
    cantidad INT,
    precio_unitario NUMERIC(12,2),
    FOREIGN KEY (id_orden) REFERENCES orden(id_orden),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE envio (
    id_envio SERIAL PRIMARY KEY,
    id_orden INT UNIQUE,
    direccion VARCHAR(200),
    estado VARCHAR(20),
    fecha_envio TIMESTAMP,
    FOREIGN KEY (id_orden) REFERENCES orden(id_orden)
);

CREATE TABLE historial_envio (
    id_historial SERIAL PRIMARY KEY,
    id_envio INT,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20),
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comentario VARCHAR(200),
    FOREIGN KEY (id_envio) REFERENCES envio(id_envio)
);

CREATE TABLE pagos (
    id_pago SERIAL PRIMARY KEY,
    id_orden INT,
    monto NUMERIC(10,2),
    estado_pago VARCHAR(20),
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_orden) REFERENCES orden(id_orden)
);


-- =========================
-- TRIGGER: DESCUENTO DE STOCK
-- Se ejecuta antes de insertar en detalle_orden.
-- Descuenta el stock del producto automáticamente.
-- =========================

CREATE OR REPLACE FUNCTION fn_descontar_stock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventario
    SET stock_actual = stock_actual - NEW.cantidad,
        actualizado_en = CURRENT_TIMESTAMP
    WHERE id_producto = NEW.id_producto
      AND stock_actual >= NEW.cantidad;

    IF NOT FOUND THEN
        RAISE EXCEPTION
        'No hay stock suficiente para el producto %', NEW.id_producto;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_descontar_stock
BEFORE INSERT ON detalle_orden
FOR EACH ROW
EXECUTE FUNCTION fn_descontar_stock();


-- =========================
-- TRIGGER: HISTORIAL DE ENVÍO
-- Registra cada cambio de estado en la tabla historial_envio.
-- =========================

CREATE OR REPLACE FUNCTION fn_guardar_historial_envio()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historial_envio (
            id_envio, estado_anterior, estado_nuevo, comentario
        ) VALUES (
            NEW.id_envio, NULL, NEW.estado, 'Registro inicial del envío'
        );

    ELSIF TG_OP = 'UPDATE'
          AND NEW.estado IS DISTINCT FROM OLD.estado THEN

        INSERT INTO historial_envio (
            id_envio, estado_anterior, estado_nuevo, comentario
        ) VALUES (
            NEW.id_envio, OLD.estado, NEW.estado, 'Cambio de estado del envío'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historial_envio
AFTER INSERT OR UPDATE OF estado ON envio
FOR EACH ROW
EXECUTE FUNCTION fn_guardar_historial_envio();


-- =========================
-- ÍNDICES
-- =========================

CREATE UNIQUE INDEX idx_usuario_email
ON usuario (email);

CREATE INDEX idx_orden_comprador_fecha
ON orden (id_comprador, fecha_orden);


-- =========================
-- DATOS DE PRUEBA (INSERT)
-- =========================

-- 50 usuarios con roles: comprador, admin, vendedor
INSERT INTO usuario (nombre, email, rol)
SELECT 
    'Usuario_' || i,
    'usuario' || i || '@mail.com',
    CASE 
        WHEN i % 3 = 0 THEN 'vendedor'
        WHEN i % 2 = 0 THEN 'admin'
        ELSE 'comprador'
    END
FROM generate_series(1, 50) AS i;

-- 50 productos asignados a vendedores
INSERT INTO producto (id_vendedor, nombre, categoria, precio)
SELECT 
    u.id_usuario,
    'Producto_' || i,
    'Categoria_' || (i % 5),
    (random() * 100 + 10)::numeric(12,2)
FROM generate_series(1, 50) AS i
JOIN usuario u ON u.rol = 'vendedor'
LIMIT 50;

-- Inventario inicial para cada producto
INSERT INTO inventario (id_producto, stock_actual, stock_minimo)
SELECT 
    id_producto,
    (random() * 50)::int,
    5
FROM producto;

-- 50 órdenes entre compradores y vendedores
INSERT INTO orden (id_comprador, id_vendedor, estado)
SELECT 
    (SELECT id_usuario FROM usuario WHERE rol = 'comprador' ORDER BY random() LIMIT 1),
    (SELECT id_usuario FROM usuario WHERE rol = 'vendedor' ORDER BY random() LIMIT 1),
    'CREADA'
FROM generate_series(1, 50);

-- Detalle de cada orden
INSERT INTO detalle_orden (id_orden, id_producto, cantidad, precio_unitario)
SELECT 
    o.id_orden,
    (SELECT id_producto FROM producto ORDER BY random() LIMIT 1),
    (random() * 5 + 1)::int,
    (random() * 100 + 10)::numeric(12,2)
FROM orden o;

-- Envío por cada orden
INSERT INTO envio (id_orden, direccion, estado)
SELECT 
    id_orden,
    'Direccion_' || id_orden,
    'PENDIENTE'
FROM orden;

-- Historial inicial de envíos
INSERT INTO historial_envio (id_envio, estado_anterior, estado_nuevo, comentario)
SELECT 
    e.id_envio,
    'PENDIENTE',
    'PREPARANDO',
    'Inicio del proceso'
FROM envio e;