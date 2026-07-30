-- ============================================================
-- YoUSAC - Auth/Catálogo Service
-- Base de datos: PostgreSQL 16
-- Microservicio: TypeScript (NestJS)
-- ============================================================

-- ── TABLAS ──────────────────────────────────────────────────

CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
    id               SERIAL PRIMARY KEY,
    email            VARCHAR(255) NOT NULL UNIQUE,
    password_hash    VARCHAR(255) NOT NULL,
    full_name        VARCHAR(255) NOT NULL,
    role_id          INT NOT NULL REFERENCES roles(id),
    is_active        BOOLEAN DEFAULT TRUE,
    is_blocked       BOOLEAN DEFAULT FALSE,
    failed_attempts  INT DEFAULT 0,
    last_login       TIMESTAMP,
    created_at       TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id         SERIAL PRIMARY KEY,
    user_id    INT NOT NULL REFERENCES users(id),
    action     VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE revoked_tokens (
    id         SERIAL PRIMARY KEY,
    token_jti  VARCHAR(255) NOT NULL UNIQUE,
    user_id    INT NOT NULL REFERENCES users(id),
    revoked_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE schools (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL UNIQUE,
    code       VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE courses (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    code        VARCHAR(50) NOT NULL UNIQUE,
    school_id   INT NOT NULL REFERENCES schools(id),
    semester    VARCHAR(50) NOT NULL,
    year        INT NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE course_teachers (
    id         SERIAL PRIMARY KEY,
    course_id  INT NOT NULL REFERENCES courses(id),
    teacher_id INT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(course_id, teacher_id)
);

CREATE TABLE enrollments (
    id          SERIAL PRIMARY KEY,
    student_id  INT NOT NULL REFERENCES users(id),
    course_id   INT NOT NULL REFERENCES courses(id),
    enrolled_at TIMESTAMP DEFAULT NOW(),
    is_active   BOOLEAN DEFAULT TRUE,
    UNIQUE(student_id, course_id)
);

CREATE TABLE recordings (
    id                   SERIAL PRIMARY KEY,
    title                VARCHAR(255) NOT NULL,
    description          TEXT,
    course_id            INT NOT NULL REFERENCES courses(id),
    teacher_id           INT NOT NULL REFERENCES users(id),
    duration_seconds     INT NOT NULL DEFAULT 0,
    video_url            VARCHAR(500) NOT NULL,
    thumbnail_url        VARCHAR(500),
    is_published         BOOLEAN DEFAULT FALSE,
    recommendation_pct   DECIMAL(5,2) DEFAULT 0.00,
    tags                 TEXT[],
    created_at           TIMESTAMP DEFAULT NOW(),
    updated_at           TIMESTAMP DEFAULT NOW()
);

-- ── ÍNDICES ─────────────────────────────────────────────────

CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_users_role        ON users(role_id);
CREATE INDEX idx_enrollments_std   ON enrollments(student_id);
CREATE INDEX idx_enrollments_crs   ON enrollments(course_id);
CREATE INDEX idx_recordings_course ON recordings(course_id);
CREATE INDEX idx_recordings_tags   ON recordings USING GIN(tags);
CREATE INDEX idx_revoked_tokens    ON revoked_tokens(token_jti);

-- ── FUNCIONES ───────────────────────────────────────────────

-- Función: validar dominio institucional
CREATE OR REPLACE FUNCTION fn_is_institutional_email(p_email VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_email ~* '^[a-zA-Z0-9._%+-]+@(ingenieria\.usac\.edu\.gt|ing\.usac\.edu\.gt)$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Función: calcular porcentaje de recomendación de un video
CREATE OR REPLACE FUNCTION fn_calculate_recommendation(p_recording_id INT)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_avg DECIMAL(5,2);
BEGIN
    -- Se asume que las calificaciones vienen del servicio de Reproducción vía sincronización
    -- Esta función opera sobre la tabla local recommendation_cache
    SELECT COALESCE(AVG(rating) * 20, 0)
    INTO v_avg
    FROM recommendation_cache
    WHERE recording_id = p_recording_id;

    RETURN v_avg;
END;
$$ LANGUAGE plpgsql;

-- Función: obtener cursos inscritos de un estudiante
CREATE OR REPLACE FUNCTION fn_get_student_courses(p_student_id INT)
RETURNS TABLE(
    course_id   INT,
    course_name VARCHAR,
    school_name VARCHAR,
    semester    VARCHAR,
    year        INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.name,
        s.name,
        c.semester,
        c.year
    FROM enrollments e
    JOIN courses c ON e.course_id = c.id
    JOIN schools s ON c.school_id = s.id
    WHERE e.student_id = p_student_id
      AND e.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- ── VISTAS ──────────────────────────────────────────────────

-- Vista: catálogo completo con información de curso y docente
CREATE OR REPLACE VIEW vw_catalog AS
SELECT
    r.id                  AS recording_id,
    r.title,
    r.description,
    r.duration_seconds,
    r.thumbnail_url,
    r.recommendation_pct,
    r.tags,
    r.is_published,
    r.created_at,
    c.id                  AS course_id,
    c.name                AS course_name,
    c.semester,
    c.year,
    s.name                AS school_name,
    u.full_name           AS teacher_name
FROM recordings r
JOIN courses  c ON r.course_id  = c.id
JOIN schools  s ON c.school_id  = s.id
JOIN users    u ON r.teacher_id = u.id
WHERE r.is_published = TRUE;

-- Vista: catálogo filtrado para un estudiante según sus inscripciones
CREATE OR REPLACE VIEW vw_student_catalog AS
SELECT
    cat.*,
    e.student_id
FROM vw_catalog cat
JOIN enrollments e ON cat.course_id = e.course_id
WHERE e.is_active = TRUE;

-- Vista: usuarios con su rol
CREATE OR REPLACE VIEW vw_users_with_role AS
SELECT
    u.id,
    u.email,
    u.full_name,
    u.is_active,
    u.is_blocked,
    u.last_login,
    u.created_at,
    r.name AS role_name
FROM users u
JOIN roles r ON u.role_id = r.id;

-- Vista: cursos con docentes asignados
CREATE OR REPLACE VIEW vw_courses_with_teachers AS
SELECT
    c.id          AS course_id,
    c.name        AS course_name,
    c.code        AS course_code,
    c.semester,
    c.year,
    s.name        AS school_name,
    u.id          AS teacher_id,
    u.full_name   AS teacher_name
FROM courses c
JOIN schools       s  ON c.school_id   = s.id
JOIN course_teachers ct ON ct.course_id = c.id
JOIN users         u  ON ct.teacher_id  = u.id;

-- ── STORED PROCEDURES ───────────────────────────────────────

-- SP: registrar nuevo usuario
CREATE OR REPLACE PROCEDURE sp_register_user(
    p_email         VARCHAR,
    p_password_hash VARCHAR,
    p_full_name     VARCHAR,
    p_role_id       INT DEFAULT 2
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT fn_is_institutional_email(p_email) THEN
        RAISE EXCEPTION 'Correo no institucional: %', p_email;
    END IF;

    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RAISE EXCEPTION 'El correo ya está registrado: %', p_email;
    END IF;

    INSERT INTO users (email, password_hash, full_name, role_id)
    VALUES (p_email, p_password_hash, p_full_name, p_role_id);
END;
$$;

-- SP: manejo de intento de login fallido
CREATE OR REPLACE PROCEDURE sp_handle_failed_login(p_email VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users
    SET failed_attempts = failed_attempts + 1,
        is_blocked = CASE WHEN failed_attempts + 1 >= 5 THEN TRUE ELSE FALSE END
    WHERE email = p_email;
END;
$$;

-- SP: inscribir estudiante en curso
CREATE OR REPLACE PROCEDURE sp_enroll_student(
    p_student_id INT,
    p_course_id  INT,
    p_admin_id   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_role_name VARCHAR;
BEGIN
    SELECT r.name INTO v_role_name
    FROM users u JOIN roles r ON u.role_id = r.id
    WHERE u.id = p_student_id;

    IF v_role_name != 'estudiante' THEN
        RAISE EXCEPTION 'El usuario % no tiene rol de estudiante', p_student_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = p_student_id AND course_id = p_course_id AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'El estudiante ya está inscrito en este curso';
    END IF;

    INSERT INTO enrollments (student_id, course_id)
    VALUES (p_student_id, p_course_id);

    INSERT INTO audit_logs (user_id, action)
    VALUES (p_admin_id, 'ENROLL_STUDENT:' || p_student_id || '_COURSE:' || p_course_id);
END;
$$;

-- SP: asignar rol a usuario
CREATE OR REPLACE PROCEDURE sp_assign_role(
    p_target_user_id INT,
    p_new_role_id    INT,
    p_admin_id       INT
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_target_user_id = p_admin_id THEN
        RAISE EXCEPTION 'No puedes modificar tu propio rol';
    END IF;

    UPDATE users SET role_id = p_new_role_id, updated_at = NOW()
    WHERE id = p_target_user_id;

    INSERT INTO audit_logs (user_id, action)
    VALUES (p_admin_id, 'ASSIGN_ROLE:' || p_new_role_id || '_TO_USER:' || p_target_user_id);
END;
$$;

-- ── TRIGGERS ────────────────────────────────────────────────

-- Trigger: actualizar updated_at automáticamente en users
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_timestamp();

CREATE TRIGGER trg_recordings_updated_at
    BEFORE UPDATE ON recordings
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_timestamp();

-- Trigger: resetear intentos fallidos al hacer login exitoso
CREATE OR REPLACE FUNCTION fn_reset_failed_attempts()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_login IS DISTINCT FROM OLD.last_login AND NEW.last_login IS NOT NULL THEN
        NEW.failed_attempts = 0;
        NEW.is_blocked = FALSE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reset_failed_attempts
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION fn_reset_failed_attempts();

-- Trigger: validar dominio antes de insertar usuario
CREATE OR REPLACE FUNCTION fn_validate_email_domain()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT fn_is_institutional_email(NEW.email) THEN
        RAISE EXCEPTION 'Dominio de correo no institucional: %', NEW.email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_email_domain
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION fn_validate_email_domain();

-- ── DATOS INICIALES ─────────────────────────────────────────

INSERT INTO roles (name, description) VALUES
    ('administrador', 'Acceso total al sistema'),
    ('estudiante',    'Acceso a grabaciones de cursos inscritos'),
    ('docente',       'Puede subir grabaciones y ver estadísticas');

INSERT INTO schools (name, code) VALUES
    ('Escuela de Ciencias y Sistemas', 'ECYS'),
    ('Escuela de Ingeniería Civil',     'EIC'),
    ('Escuela de Ingeniería Mecánica',  'EIM'),
    ('Escuela de Ingeniería Química',   'EIQ');

