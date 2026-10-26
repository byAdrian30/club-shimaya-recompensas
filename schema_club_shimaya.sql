-- ==============================================================================
-- SISTEMA DE FIDELIZACIÓN CLUB SHIMAYA RAMEN
-- Esquema de Base de Datos Relacional (PostgreSQL / Supabase)
-- Sincronizado con ID POS (Sede Chiclayo) y Regla de 6% Cashback
-- ==============================================================================

-- 1. Habilitar extensión para UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 2. TABLA: clientes_fidelidad
-- Candado de Identidad: DNI es la llave primaria única de 8 dígitos.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes_fidelidad (
    dni VARCHAR(8) PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(15),
    email VARCHAR(100),
    puntos_disponibles INT NOT NULL DEFAULT 0 CHECK (puntos_disponibles >= 0),
    puntos_historicos INT NOT NULL DEFAULT 0 CHECK (puntos_historicos >= 0),
    hito_actual INT NOT NULL DEFAULT 0 CHECK (hito_actual >= 0 AND hito_actual <= 10),
    nivel_ciclo INT NOT NULL DEFAULT 1 CHECK (nivel_ciclo >= 1), -- Nivel 1: Regular, Nivel 2: Sensei VIP (1.2x puntos)
    fecha_ultima_visita DATE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE clientes_fidelidad IS 'Registro maestro de clientes fidelizados indexados por DNI único.';

-- ------------------------------------------------------------------------------
-- 3. TABLA: catalogo_hitos_mapa
-- Configuración maestra de las 10 estaciones de la ruta con platos reales de ID POS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS catalogo_hitos_mapa (
    numero_estacion INT PRIMARY KEY CHECK (numero_estacion BETWEEN 1 AND 10),
    nombre_hito VARCHAR(100) NOT NULL,
    premio_desbloqueado VARCHAR(150) NOT NULL,
    categoria_pos VARCHAR(50) NOT NULL,
    precio_carta_referencial NUMERIC(8, 2) NOT NULL,
    consumo_minimo_requerido NUMERIC(8, 2) NOT NULL DEFAULT 25.00,
    es_premio_mayor BOOLEAN NOT NULL DEFAULT FALSE
);

-- Inserción de las 10 estaciones de la Ruta Shimaya (Nombres y precios oficiales ID POS)
INSERT INTO catalogo_hitos_mapa 
(numero_estacion, nombre_hito, premio_desbloqueado, categoria_pos, precio_carta_referencial, consumo_minimo_requerido, es_premio_mayor)
VALUES
(1, 'Hito Inicial', 'Te De Jazmin Taza', 'JUGOS', 5.00, 25.00, FALSE),
(2, 'Parada Menor', 'Porción Fideo Ramen', 'GUARNICIONES', 8.00, 25.00, FALSE),
(3, 'Hito Entrada', 'Age Gyozas x 6 und.', 'ENTRADAS', 20.00, 25.00, FALSE),
(4, 'Beneficio Puntos', 'Multiplicador x2 de Puntos', 'BENEFICIO', 10.00, 25.00, FALSE),
(5, 'Hito Mitad', 'Puchi Kurimu', 'OTROS', 15.00, 25.00, FALSE),
(6, 'Parada Menor', 'Te Afrutado Taza', 'JUGOS', 8.00, 25.00, FALSE),
(7, 'Hito Refresco', 'SODA FRUTOS DEL BOSQUE', 'JUGOS', 12.00, 25.00, FALSE),
(8, 'Piqueo Estrella', 'Maki Acevichado 1/2 Tabla', 'MAKIS 1/2 TABLA', 16.00, 25.00, FALSE),
(9, 'Parada Menor', 'Yakitori', 'ENTRADAS', 23.00, 25.00, FALSE),
(10, '¡GRAN FINAL DE CICLO!', 'Tonkotsu Ramen S o Chasu Ramen S Gratis', 'RAMEN S', 25.00, 25.00, TRUE)
ON CONFLICT (numero_estacion) DO UPDATE SET
    premio_desbloqueado = EXCLUDED.premio_desbloqueado,
    categoria_pos = EXCLUDED.categoria_pos,
    precio_carta_referencial = EXCLUDED.precio_carta_referencial;

-- ------------------------------------------------------------------------------
-- 4. TABLA: catalogo_tienda_puntos
-- Catálogo oficial de canje (Regla 1 Sol = 1 Punto | 6% Cashback)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS catalogo_tienda_puntos (
    id VARCHAR(50) PRIMARY KEY,
    nombre_producto VARCHAR(150) NOT NULL,
    categoria_pos VARCHAR(50) NOT NULL,
    precio_carta NUMERIC(8, 2) NOT NULL,
    puntos_requeridos INT NOT NULL, -- 1 Sol = 1 Punto
    consumo_equivalente NUMERIC(10, 2) NOT NULL, -- Puntos / 0.06
    icono VARCHAR(10) DEFAULT '🍜',
    disponible BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO catalogo_tienda_puntos 
(id, nombre_producto, categoria_pos, precio_carta, puntos_requeridos, consumo_equivalente, icono)
VALUES
('te_jazmin', 'Te De Jazmin Taza', 'JUGOS', 5.00, 5, 83.33, '🍵'),
('fideo_ramen', 'Porción Fideo Ramen', 'GUARNICIONES', 8.00, 8, 133.33, '🍜'),
('te_afrutado', 'Te Afrutado Taza', 'JUGOS', 8.00, 8, 133.33, '🍹'),
('soda_frutos', 'SODA FRUTOS DEL BOSQUE', 'JUGOS', 12.00, 12, 200.00, '🍹'),
('puchi_kurimu', 'Puchi Kurimu', 'OTROS', 15.00, 15, 250.00, '🧁'),
('maki_acevichado_media', 'Maki Acevichado 1/2 Tabla', 'MAKIS 1/2 TABLA', 16.00, 16, 266.67, '🍱'),
('maki_furai_media', 'Maki Furai 1/2 Tabla', 'MAKIS 1/2 TABLA', 16.00, 16, 266.67, '🍱'),
('age_gyozas', 'Age Gyozas x 6 und.', 'ENTRADAS', 20.00, 20, 333.33, '🥟'),
('vale_20', 'Vale de S/ 20.00 de Descuento', 'CUPÓN', 20.00, 20, 333.33, '🎟️'),
('gyozas_vapor', 'Gyozas x 6und.', 'ENTRADAS', 21.00, 21, 350.00, '🥟'),
('ebi_furai', 'Ebi Furai x 6 und.', 'ENTRADAS', 23.00, 23, 383.33, '🍤'),
('yakitori', 'Yakitori', 'ENTRADAS', 23.00, 23, 383.33, '🍢'),
('karage', 'Karage', 'ENTRADAS', 23.00, 23, 383.33, '🍗'),
('tonkotsu_s', 'Tonkotsu Ramen S', 'RAMEN S', 24.00, 24, 400.00, '🍜'),
('chasu_s', 'Chasu Ramen S', 'RAMEN S', 25.00, 25, 416.67, '🍜'),
('cheesecake', 'Cheesecake japones', 'OTROS', 25.00, 25, 416.67, '🍰'),
('alitas_bbq', 'Alitas BBQ x 6 unid', 'ALITAS', 25.00, 25, 416.67, '🍗'),
('alitas_acevichadas', 'Alitas acevichadas x 6 unid', 'ALITAS', 25.00, 25, 416.67, '🍗'),
('maki_acevichado_tabla', 'Maki Acevichado 1 Tabla', 'MAKIS 1 TABLA', 27.00, 27, 450.00, '🍣'),
('chaufa', 'Chaufa Shimaya', 'PLATOS DE FONDO', 29.00, 29, 483.33, '🍚'),
('chasu_m', 'Chasu Ramen M', 'RAMEN M', 34.00, 34, 566.67, '🔥'),
('batayaki', 'Batayaki ramen', 'PLATOS DE FONDO', 34.00, 34, 566.67, '🔥')
ON CONFLICT (id) DO UPDATE SET
    nombre_producto = EXCLUDED.nombre_producto,
    precio_carta = EXCLUDED.precio_carta,
    puntos_requeridos = EXCLUDED.puntos_requeridos,
    consumo_equivalente = EXCLUDED.consumo_equivalente;

-- ------------------------------------------------------------------------------
-- 5. TABLA: registro_visitas_boletas
-- Candado Transaccional: comprobante_id UNIQUE impide doble registro de ticket.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS registro_visitas_boletas (
    comprobante_id VARCHAR(30) PRIMARY KEY, -- Formato SUNAT: B001-00045821 o B002-00012900
    dni VARCHAR(8) NOT NULL REFERENCES clientes_fidelidad(dni) ON DELETE RESTRICT,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto_total NUMERIC(10, 2) NOT NULL CHECK (monto_total > 0),
    puntos_generados INT NOT NULL DEFAULT 0,
    avanzo_hito BOOLEAN NOT NULL DEFAULT FALSE,
    estado VARCHAR(15) NOT NULL DEFAULT 'ACTIVA' CHECK (estado IN ('ACTIVA', 'ANULADA')),
    cajero_codigo VARCHAR(20) DEFAULT 'CAJA-01',
    observaciones TEXT
);

CREATE INDEX IF NOT EXISTS idx_boletas_dni ON registro_visitas_boletas(dni);
CREATE INDEX IF NOT EXISTS idx_boletas_fecha ON registro_visitas_boletas(fecha_hora);

-- ------------------------------------------------------------------------------
-- 6. TABLA: recompensas_cliente
-- Control de premios emitidos y canjeados (Cupones digitales)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recompensas_cliente (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_cupon VARCHAR(25) NOT NULL UNIQUE, -- Código: SHIMA-XXXX-OK
    dni VARCHAR(8) NOT NULL REFERENCES clientes_fidelidad(dni) ON DELETE CASCADE,
    tipo_origen VARCHAR(10) NOT NULL CHECK (tipo_origen IN ('RUTA', 'TIENDA')),
    descripcion_premio VARCHAR(150) NOT NULL,
    puntos_deducidos INT NOT NULL DEFAULT 0,
    estado VARCHAR(15) NOT NULL DEFAULT 'DISPONIBLE' CHECK (estado IN ('DISPONIBLE', 'CANJEADO', 'VENCIDO')),
    comprobante_canje_id VARCHAR(30),
    fecha_generacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_canje TIMESTAMPTZ,
    fecha_expiracion TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '45 days')
);

CREATE INDEX IF NOT EXISTS idx_recompensas_dni_estado ON recompensas_cliente(dni, estado);

-- ------------------------------------------------------------------------------
-- 7. PROCEDIMIENTO PRINCIPAL EN CAJA: fn_procesar_boleta_caja
-- Aplica asignación con DNI, cálculo de 6% cashback en puntos y cooldown de 1 hito/día
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_procesar_boleta_caja(
    p_comprobante_id VARCHAR(30),
    p_dni VARCHAR(8),
    p_monto NUMERIC(10, 2),
    p_cajero_codigo VARCHAR(20) DEFAULT 'CAJA-01'
)
RETURNS JSONB AS $$
DECLARE
    v_cliente RECORD;
    v_hito_config RECORD;
    v_multiplicador NUMERIC(3, 1) := 1.0;
    v_puntos_finales INT;
    v_avanzo_hito BOOLEAN := FALSE;
    v_nuevo_hito INT;
    v_nuevo_ciclo INT;
    v_hoy DATE := CURRENT_DATE;
BEGIN
    -- 1. Candado Antifraude: DNI nominal obligatorio (prohibir 00000000)
    IF p_dni IS NULL OR LENGTH(TRIM(p_dni)) != 8 OR p_dni = '00000000' THEN
        RAISE EXCEPTION 'DNI inválido o Clientes Varios (00000000). El DNI nominal es obligatorio.';
    END IF;

    -- 2. Asegurar existencia del cliente en Supabase
    INSERT INTO clientes_fidelidad (dni, nombre, puntos_disponibles, puntos_historicos, hito_actual, nivel_ciclo)
    VALUES (p_dni, 'Cliente Shimaya (' || SUBSTRING(p_dni FROM 1 FOR 3) || '***)', 0, 0, 0, 1)
    ON CONFLICT (dni) DO NOTHING;

    SELECT * INTO v_cliente FROM clientes_fidelidad WHERE dni = p_dni FOR UPDATE;

    -- 3. Cálculo de Puntos (Regla Oficial: 6% de Cashback)
    IF v_cliente.nivel_ciclo >= 2 THEN
        v_multiplicador := 1.2; -- Nivel Sensei VIP permanente
    END IF;
    v_puntos_finales := ROUND((p_monto * 0.06) * v_multiplicador);

    -- 4. Candado de Cooldown Diario (Máximo 1 hito de avance por día calendario)
    IF (v_cliente.fecha_ultima_visita IS NULL OR v_cliente.fecha_ultima_visita < v_hoy) THEN
        v_nuevo_hito := v_cliente.hito_actual + 1;
        IF v_nuevo_hito > 10 THEN
            v_nuevo_hito := 1;
            v_nuevo_ciclo := v_cliente.nivel_ciclo + 1;
        ELSE
            v_nuevo_ciclo := v_cliente.nivel_ciclo;
        END IF;

        SELECT * INTO v_hito_config FROM catalogo_hitos_mapa WHERE numero_estacion = v_nuevo_hito;
        
        IF p_monto >= v_hito_config.consumo_minimo_requerido THEN
            v_avanzo_hito := TRUE;
        END IF;
    END IF;

    -- 5. Registrar la boleta (Candado comprobante_id UNIQUE)
    INSERT INTO registro_visitas_boletas 
    (comprobante_id, dni, monto_total, puntos_generados, avanzo_hito, estado, cajero_codigo)
    VALUES 
    (p_comprobante_id, p_dni, p_monto, v_puntos_finales, v_avanzo_hito, 'ACTIVA', p_cajero_codigo);

    -- 6. Actualizar cliente y emitir cupón de ruta si avanzó estación
    IF v_avanzo_hito THEN
        UPDATE clientes_fidelidad
        SET puntos_disponibles = puntos_disponibles + v_puntos_finales,
            puntos_historicos = puntos_historicos + v_puntos_finales,
            hito_actual = v_nuevo_hito,
            nivel_ciclo = v_nuevo_ciclo,
            fecha_ultima_visita = v_hoy,
            updated_at = NOW()
        WHERE dni = p_dni;

        INSERT INTO recompensas_cliente 
        (codigo_cupon, dni, tipo_origen, descripcion_premio)
        VALUES 
        ('RUTA-' || SUBSTRING(p_dni FROM 5 FOR 4) || '-H' || v_nuevo_hito || '-' || FLOOR(RANDOM() * 900 + 100)::TEXT, 
         p_dni, 'RUTA', v_hito_config.premio_desbloqueado);
    ELSE
        UPDATE clientes_fidelidad
        SET puntos_disponibles = puntos_disponibles + v_puntos_finales,
            puntos_historicos = puntos_historicos + v_puntos_finales,
            updated_at = NOW()
        WHERE dni = p_dni;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'dni', p_dni,
        'comprobante_id', p_comprobante_id,
        'puntos_sumados', v_puntos_finales,
        'avanzo_hito', v_avanzo_hito,
        'hito_actual', CASE WHEN v_avanzo_hito THEN v_nuevo_hito ELSE v_cliente.hito_actual END,
        'nivel_ciclo', CASE WHEN v_avanzo_hito THEN v_nuevo_ciclo ELSE v_cliente.nivel_ciclo END
    );
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- 8. VISTA DE CONSULTA PÚBLICA PARA EL CLIENTE: vw_consulta_cliente
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_consulta_cliente AS
SELECT 
    c.dni,
    c.nombre,
    c.puntos_disponibles,
    c.puntos_historicos,
    c.hito_actual,
    c.nivel_ciclo,
    c.fecha_ultima_visita,
    COALESCE(h.premio_desbloqueado, 'Inicio de Ruta') AS proximo_premio,
    COALESCE(h.consumo_minimo_requerido, 25.00) AS consumo_minimo_proximo
FROM clientes_fidelidad c
LEFT JOIN catalogo_hitos_mapa h ON h.numero_estacion = LEAST(10, c.hito_actual + 1);

-- ------------------------------------------------------------------------------
-- 9. SEGURIDAD: Políticas RLS (Row Level Security) para consulta pública por DNI
-- ------------------------------------------------------------------------------
ALTER TABLE clientes_fidelidad ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalogo_hitos_mapa ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalogo_tienda_puntos ENABLE ROW LEVEL SECURITY;
ALTER TABLE recompensas_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE registro_visitas_boletas ENABLE ROW LEVEL SECURITY;

-- Permitir lectura de catálogos y consulta por DNI
CREATE POLICY "Lectura pública catálogos" ON catalogo_hitos_mapa FOR SELECT USING (true);
CREATE POLICY "Lectura pública tienda" ON catalogo_tienda_puntos FOR SELECT USING (true);
CREATE POLICY "Lectura cliente por DNI" ON clientes_fidelidad FOR SELECT USING (true);
CREATE POLICY "Lectura cupones propios" ON recompensas_cliente FOR SELECT USING (true);
CREATE POLICY "Lectura historial boletas" ON registro_visitas_boletas FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 10. DATOS SEMILLA DE PRUEBA (CLIENTES REALES)
-- ------------------------------------------------------------------------------
INSERT INTO clientes_fidelidad 
(dni, nombre, puntos_disponibles, puntos_historicos, hito_actual, nivel_ciclo, fecha_ultima_visita)
VALUES 
('74829103', 'Marco Ramos', 22, 22, 5, 1, '2026-10-24'),
('45102938', 'Lucía Mendoza', 5, 5, 1, 1, '2026-10-20'),
('74156527', 'Adrian Smith Barranzuela', 35, 45, 9, 1, '2026-10-25')
ON CONFLICT (dni) DO UPDATE SET
    puntos_disponibles = EXCLUDED.puntos_disponibles,
    hito_actual = EXCLUDED.hito_actual;

INSERT INTO registro_visitas_boletas 
(comprobante_id, dni, fecha_hora, monto_total, puntos_generados, avanzo_hito, estado)
VALUES
('B002-00045821', '74829103', '2026-10-24 14:30:00-05', 85.00, 5, TRUE, 'ACTIVA'),
('B002-00045110', '74829103', '2026-10-18 20:15:00-05', 120.00, 7, TRUE, 'ACTIVA'),
('B002-00043900', '74829103', '2026-10-05 13:45:00-05', 65.00, 4, TRUE, 'ACTIVA'),
('B002-00042100', '74829103', '2026-09-25 21:00:00-05', 70.00, 4, TRUE, 'ACTIVA'),
('B002-00040500', '45102938', '2026-10-20 15:10:00-05', 85.00, 5, TRUE, 'ACTIVA')
ON CONFLICT (comprobante_id) DO NOTHING;
