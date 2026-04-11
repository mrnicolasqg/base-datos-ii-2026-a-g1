CREATE DATABASE backup_practica;
USE backup_practica;

CREATE TABLE estudiante (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    nota DECIMAL(3,2)
);

INSERT INTO estudiante(nombre, nota) VALUES
('Juan Perez', 4.5),
('Maria Lopez', 3.8),
('Carlos Ruiz', 2.9);
SET SQL_SAFE_UPDATES = 0;

DELETE FROM estudiante;

SELECT * FROM estudiante;