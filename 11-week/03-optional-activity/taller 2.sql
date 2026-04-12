
CREATE DATABASE taller_unidad2;
USE taller_unidad2;

-- =====================================
-- 1. TABLAS BASE
-- =====================================

CREATE TABLE espacio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    capacidad INT
);

CREATE TABLE reserva (
    id INT AUTO_INCREMENT PRIMARY KEY,
    espacio_id INT,
    fecha DATE,
    hora_inicio TIME,
    hora_fin TIME,
    estado VARCHAR(20),
    FOREIGN KEY (espacio_id) REFERENCES espacio(id)
);

-- =====================================
-- 2. USUARIOS Y PERMISOS
-- =====================================

CREATE USER IF NOT EXISTS 'u_lector'@'localhost' IDENTIFIED BY '1234';
CREATE USER IF NOT EXISTS 'u_reservas'@'localhost' IDENTIFIED BY '1234';

GRANT SELECT ON taller_unidad2.* TO 'u_lector'@'localhost';

GRANT SELECT, INSERT ON taller_unidad2.reserva TO 'u_reservas'@'localhost';
GRANT SELECT ON taller_unidad2.espacio TO 'u_reservas'@'localhost';

FLUSH PRIVILEGES;

-- =====================================
-- 3. TRIGGER BEFORE INSERT
-- VALIDAR HORAS
-- =====================================

DELIMITER $$

CREATE TRIGGER trg_validar_horas
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    IF NEW.hora_inicio >= NEW.hora_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La hora_inicio debe ser menor que hora_fin';
    END IF;
END$$

DELIMITER ;

-- =====================================
-- 4. TRIGGER BEFORE INSERT
-- ESTADO AUTOMATICO
-- =====================================

DELIMITER $$

CREATE TRIGGER trg_estado_default
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    IF NEW.estado IS NULL THEN
        SET NEW.estado = 'ACTIVA';
    END IF;
END$$

DELIMITER ;

-- =====================================
-- 5. DATOS DE PRUEBA
-- =====================================

INSERT INTO espacio (nombre, capacidad) VALUES
('Sala de reuniones', 12),
('Auditorio central', 80),
('Cancha multiple', 30);

-- Insercion correcta
INSERT INTO reserva (espacio_id, fecha, hora_inicio, hora_fin, estado)
VALUES (1, '2026-03-01', '08:00:00', '10:00:00', NULL);

-- Otro insert correcto
INSERT INTO reserva (espacio_id, fecha, hora_inicio, hora_fin, estado)
VALUES (2, '2026-03-01', '14:00:00', '16:00:00', 'PENDIENTE');

SELECT * FROM reserva;

-- =====================================
-- 6. INSERCION INVALIDA (DEBE FALLAR)
-- =====================================

INSERT INTO reserva (espacio_id, fecha, hora_inicio, hora_fin, estado)
VALUES (1, '2026-03-01', '12:00:00', '10:00:00', NULL);

-- =====================================
-- 7. EXPLAIN ANTES DEL INDICE
-- =====================================

EXPLAIN SELECT *
FROM reserva
WHERE fecha = '2026-03-01';

-- =====================================
-- 8. CREAR INDICE
-- =====================================

CREATE INDEX idx_reserva_fecha ON reserva(fecha);

-- =====================================
-- 9. EXPLAIN DESPUES DEL INDICE
-- =====================================

EXPLAIN SELECT *
FROM reserva
WHERE fecha = '2026-03-01';

-- =====================================
-- 10. CONSULTAS FINALES
-- =====================================

SELECT * FROM espacio;
SELECT * FROM reserva;