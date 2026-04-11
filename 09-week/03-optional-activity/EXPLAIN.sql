
CREATE DATABASE indices_practica;
USE indices_practica;

-- Tabla estudiante
CREATE TABLE estudiante (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    semestre INT
);

-- Tabla asignatura
CREATE TABLE asignatura (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100)
);

-- Tabla matricula
CREATE TABLE matricula (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estudiante_id INT,
    asignatura_id INT,
    nota DECIMAL(3,2),
    FOREIGN KEY (estudiante_id) REFERENCES estudiante(id),
    FOREIGN KEY (asignatura_id) REFERENCES asignatura(id)
);

INSERT INTO estudiante(nombre, semestre) VALUES
('Juan', 1), ('Maria', 2), ('Carlos', 1), ('Ana', 3);

INSERT INTO asignatura(nombre) VALUES
('BD'), ('Programacion'), ('Redes');

INSERT INTO matricula(estudiante_id, asignatura_id, nota) VALUES
(1,1,4.5),(1,2,3.5),
(2,1,4.0),(3,2,2.8),
(4,3,4.7);

SELECT * FROM matricula WHERE estudiante_id = 1;

SELECT * FROM matricula WHERE asignatura_id = 2;

SELECT e.nombre, a.nombre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id
JOIN asignatura a ON m.asignatura_id = a.id;

EXPLAIN SELECT * FROM matricula WHERE estudiante_id = 1;
EXPLAIN SELECT * FROM matricula WHERE asignatura_id = 2;
EXPLAIN SELECT e.nombre, a.nombre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id
JOIN asignatura a ON m.asignatura_id = a.id;

CREATE INDEX idx_estudiante ON matricula(estudiante_id);

CREATE INDEX idx_compuesto ON matricula(estudiante_id, asignatura_id);

CREATE INDEX idx_join ON matricula(asignatura_id);

EXPLAIN SELECT * FROM matricula WHERE estudiante_id = 1;
EXPLAIN SELECT * FROM matricula WHERE asignatura_id = 2;
EXPLAIN SELECT e.nombre, a.nombre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id
JOIN asignatura a ON m.asignatura_id = a.id;