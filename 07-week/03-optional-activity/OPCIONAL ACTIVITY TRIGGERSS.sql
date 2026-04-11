
-- ==========================================
-- 1. Tabla principal
-- ==========================================
CREATE DATABASE mini_reto_triggers;
USE mini_reto_triggers;
CREATE TABLE estudiante (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nota_final DECIMAL(3,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. Tabla de auditoría
-- ==========================================
CREATE TABLE audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabla VARCHAR(50) NOT NULL,
    operacion VARCHAR(10) NOT NULL,
    registro_id INT,
    datos_anteriores JSON,
    datos_nuevos JSON,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO estudiante(nombre, nota_final)
VALUES 
('   carlos ramirez   ', 3.80),
('   ana martinez   ', 4.20),
('   luis fernando   ', 2.90);
SELECT * FROM estudiante;
UPDATE estudiante
SET nombre = '   maria lopez   ', nota_final = 4.80
WHERE id = 1;
DELETE FROM estudiante
WHERE id = 2;

-- ==========================================
-- 3. Trigger BEFORE: normalizar nombre
-- TRIM + INITCAP manual en MySQL
-- ==========================================

DELIMITER $$

CREATE TRIGGER trg_before_insert_estudiante
BEFORE INSERT ON estudiante
FOR EACH ROW
BEGIN
    SET NEW.nombre = TRIM(NEW.nombre);

    SET NEW.nombre = CONCAT(
        UPPER(LEFT(NEW.nombre, 1)),
        LOWER(SUBSTRING(NEW.nombre, 2))
    );

    IF NEW.nota_final < 0 OR NEW.nota_final > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La nota_final debe estar entre 0 y 5';
    END IF;
END$$

DELIMITER ;

-- ==========================================
-- 4. Trigger BEFORE UPDATE:
-- normalizar nombre + updated_at + validar nota
-- ==========================================

DELIMITER $$

CREATE TRIGGER trg_before_update_estudiante
BEFORE UPDATE ON estudiante
FOR EACH ROW
BEGIN
    SET NEW.nombre = TRIM(NEW.nombre);

    SET NEW.nombre = CONCAT(
        UPPER(LEFT(NEW.nombre, 1)),
        LOWER(SUBSTRING(NEW.nombre, 2))
    );

    SET NEW.updated_at = CURRENT_TIMESTAMP;

    IF NEW.nota_final < 0 OR NEW.nota_final > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La nota_final debe estar entre 0 y 5';
    END IF;
END$$

DELIMITER ;

-- ==========================================
-- 5. Trigger AFTER INSERT: auditoría
-- ==========================================

DELIMITER $$

CREATE TRIGGER trg_after_insert_estudiante
AFTER INSERT ON estudiante
FOR EACH ROW
BEGIN
    INSERT INTO audit(tabla, operacion, registro_id, datos_anteriores, datos_nuevos)
    VALUES (
        'estudiante',
        'INSERT',
        NEW.id,
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'nombre', NEW.nombre,
            'nota_final', NEW.nota_final,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        )
    );
END$$

DELIMITER ;

-- ==========================================
-- 6. Trigger AFTER UPDATE: auditoría
-- ==========================================

DELIMITER $$

CREATE TRIGGER trg_after_update_estudiante
AFTER UPDATE ON estudiante
FOR EACH ROW
BEGIN
    INSERT INTO audit(tabla, operacion, registro_id, datos_anteriores, datos_nuevos)
    VALUES (
        'estudiante',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'id', OLD.id,
            'nombre', OLD.nombre,
            'nota_final', OLD.nota_final,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'nombre', NEW.nombre,
            'nota_final', NEW.nota_final,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        )
    );
END$$

DELIMITER ;

-- ==========================================
-- 7. Trigger AFTER DELETE: auditoría
-- ==========================================

DELIMITER $$

CREATE TRIGGER trg_after_delete_estudiante
AFTER DELETE ON estudiante
FOR EACH ROW
BEGIN
    INSERT INTO audit(tabla, operacion, registro_id, datos_anteriores, datos_nuevos)
    VALUES (
        'estudiante',
        'DELETE',
        OLD.id,
        JSON_OBJECT(
            'id', OLD.id,
            'nombre', OLD.nombre,
            'nota_final', OLD.nota_final,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL
    );
END$$

DELIMITER ;

-- ==========================================
-- 8. PRUEBAS
-- ==========================================

-- 1. INSERT OK
INSERT INTO estudiante(nombre, nota_final)
VALUES ('   juan perez   ', 4.50);

SELECT * FROM estudiante;

-- 2. UPDATE OK
UPDATE estudiante
SET nombre = '   maria lopez   ', nota_final = 4.80
WHERE id = 1;

SELECT * FROM estudiante;

-- 3. DELETE OK
DELETE FROM estudiante
WHERE id = 1;

SELECT * FROM estudiante;

-- 4. OPERACIÓN FALLIDA POR VALIDACIÓN
INSERT INTO estudiante(nombre, nota_final)
VALUES ('carlos ramirez', 5.80);

-- 5. VER AUDITORÍA
SELECT * FROM audit;