-- ============================================================
--  TABLE: users
-- ============================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(60) UNIQUE NOT NULL,
    password TEXT,
    enable BOOLEAN,
    role VARCHAR(10)
);

-- ============================================================
--  TABLE: citizens
-- ============================================================
CREATE TABLE citizens (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(100),
    correo VARCHAR(120) UNIQUE
);

-- ============================================================
--  TABLE: grids 
-- ============================================================
CREATE TABLE grids (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    grid_lat_idx INT,
    grid_lon_idx INT,
    centro_lat NUMERIC(10,6),
    centro_lon NUMERIC(10,6),
    UNIQUE (grid_lat_idx, grid_lon_idx)
);

-- ============================================================
--  TABLE: favorite_areas
-- ============================================================
CREATE TABLE favorite_areas (
    id SERIAL PRIMARY KEY,
    citizen_id INT NOT NULL REFERENCES citizens(id) ON DELETE CASCADE,
    grid_id INT NOT NULL REFERENCES grids(id) ON DELETE CASCADE,
    fecha_agregado TIMESTAMP DEFAULT NOW(),
    UNIQUE (citizen_id, grid_id)
);

-- ============================================================
--  TABLE: datasets
-- ============================================================
CREATE TABLE datasets (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    fuente VARCHAR(100),
    ruta_archivo TEXT,
    num_registros INT,
    descripcion TEXT,
    fecha_ingreso TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  TABLE: ml_models
-- ============================================================
CREATE TABLE ml_models (
    id SERIAL PRIMARY KEY,
    nombre_modelo VARCHAR(100),
    dataset_id INT REFERENCES datasets(id) ON DELETE SET NULL,
    version VARCHAR(20),
    ruta_modelo TEXT,
    precision NUMERIC(5,2),
    accuracy NUMERIC(5,2),
    recall NUMERIC(5,2),
    f1 NUMERIC(5,2),
    auc NUMERIC(5,2),
    fecha_entrenamiento TIMESTAMP
);

-- ============================================================
--  TABLE: predictions_grid
-- ============================================================
CREATE TABLE predictions_grid (
    id SERIAL PRIMARY KEY,
    grid_id INT NOT NULL REFERENCES grids(id) ON DELETE CASCADE,
    score_riesgo INT,  -- 1=bajo, 2=medio, 3=alto
	tramo_horario VARCHAR(20), -- [CORRECCIÓN: Necesaria para el índice y filtrado]    
    nivel_riesgo VARCHAR(20),--'bajo','medio','alto'
    fecha_prediccion TIMESTAMP
);

-- ============================================================
--  TABLE: user_alerts
-- ============================================================
CREATE TABLE user_alerts (
    id SERIAL PRIMARY KEY,
    citizen_id INT NOT NULL REFERENCES citizens(id) ON DELETE CASCADE,
    grid_id INT NOT NULL REFERENCES grids(id) ON DELETE CASCADE,
    titulo VARCHAR(100),
    tipo_incidente VARCHAR(50) NOT NULL,
    descripcion TEXT,
    nivel_riesgo VARCHAR(20) CHECK (nivel_riesgo IN ('bajo', 'medio', 'alto')),
    ruta_foto TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'Recibido' CHECK (estado IN ('Recibido', 'En proceso', 'Cerrado')),
    fecha TIMESTAMP NOT NULL DEFAULT NOW()
);

-- NUEVAS TABLAS 

-- ============================================================
--  TABLE: zone_reviews
-- ============================================================
CREATE TABLE zone_reviews (
    id SERIAL PRIMARY KEY,
    citizen_id INT NOT NULL REFERENCES citizens(id) ON DELETE CASCADE,
    grid_id INT NOT NULL REFERENCES grids(id) ON DELETE CASCADE,
    calificacion INT CHECK (calificacion BETWEEN 1 AND 5), -- 1 a 5 estrellas
    comentario TEXT NOT NULL,
    fecha_publicacion TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  TABLE: review_likes
-- ============================================================
CREATE TABLE review_likes (
    id SERIAL PRIMARY KEY,
    citizen_id INT REFERENCES citizens(id) ON DELETE CASCADE,
    review_id INT REFERENCES zone_reviews(id) ON DELETE CASCADE,
    UNIQUE (citizen_id, review_id)
);

-- ============================================================
--  TABLE: police_stations
-- ============================================================
CREATE TABLE police_stations (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(20),
    latitud NUMERIC(10,6) NOT NULL,
    longitud NUMERIC(10,6) NOT NULL,
    distrito VARCHAR(50),
    fecha_registro TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  TABLE: app_feedback
-- ============================================================
CREATE TABLE app_feedback (
    id SERIAL PRIMARY KEY,
    citizen_id INT UNIQUE REFERENCES citizens(id) ON DELETE CASCADE,
    estrellas INT CHECK (estrellas BETWEEN 1 AND 5),
    comentario TEXT,
    fecha TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  TABLE: password_reset_tokens 
-- ============================================================
CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    codigo VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
--  INDEXES (Opcionales para rendimiento)
-- ============================================================
CREATE INDEX idx_grids_coords ON grids (centro_lat, centro_lon);
CREATE INDEX idx_alerts_citizen ON user_alerts (citizen_id);
CREATE INDEX idx_favorite_citizen ON favorite_areas (citizen_id);
CREATE INDEX idx_pred_grid_tramo ON predictions_grid (grid_id, tramo_horario, fecha_prediccion);
CREATE INDEX idx_police_coords ON police_stations (latitud, longitud);
CREATE INDEX idx_police_district ON police_stations (distrito);
CREATE INDEX idx_zone_reviews_grid_fecha ON zone_reviews (grid_id, fecha_publicacion DESC);
CREATE INDEX idx_password_reset_user ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_token ON password_reset_tokens(codigo);
--Ultima version