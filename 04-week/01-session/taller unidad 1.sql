CREATE DATABASE taller_unidad1;
USE taller_unidad1;
CREATE TABLE cliente (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100)
);

CREATE TABLE producto (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(20),
  nombre VARCHAR(100),
  precio DECIMAL(10,2)
);

CREATE TABLE orden (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT,
  producto_id INT,
  fecha_orden DATE,
  cantidad INT,
  total DECIMAL(10,2)
);
INSERT INTO cliente (nombre) VALUES
('Carlos'),
('Maria'),
('Andres'),
('Sofia'),
('Juan');
INSERT INTO producto (codigo, nombre, precio) VALUES
('P01', 'CocaCola', 6500),
('P02', 'Doritos', 4200),
('P03', 'Papas', 3800),
('P04', 'Galletas', 2500),
('P05', 'Chocolatina', 1800),
('P06', 'Pan', 7200),
('P07', 'Leche', 4500),
('P08', 'Arroz', 5200),
('P09', 'Huevos', 10200),
('P10', 'Aceite', 14500);

INSERT INTO orden (cliente_id, producto_id, fecha_orden, cantidad, total) VALUES
(1, 1, '2026-01-10', 1, 6500),
(2, 1, '2026-02-05', 2, 13000),
(3, 1, '2026-03-01', 1, 6500),
(1, 2, '2026-01-15', 1, 4200),
(4, 2, '2026-02-20', 2, 8400),
(5, 2, '2026-03-10', 1, 4200),
(2, 3, '2026-03-15', 1, 3800),
(3, 4, '2026-04-01', 2, 5000),
(4, 5, '2026-04-10', 2, 3600),
(5, 6, '2026-04-20', 1, 7200);

USE taller_unidad1;
-- CONSULTA 1
-- Órdenes realizadas en el año 2026
SELECT
  cliente.nombre AS cliente,
  producto.nombre AS producto,
  orden.fecha_orden,
  orden.total
FROM orden
INNER JOIN cliente ON orden.cliente_id = cliente.id
INNER JOIN producto ON orden.producto_id = producto.id
WHERE YEAR(orden.fecha_orden) = 2026
ORDER BY orden.fecha_orden;
-- CONSULTA 2
-- Productos vendidos 3 o más veces en 2026
SELECT
  producto.nombre AS producto,
  COUNT(orden.id) AS total_ordenes
FROM orden
INNER JOIN producto ON orden.producto_id = producto.id
WHERE YEAR(orden.fecha_orden) = 2026
GROUP BY producto.nombre
HAVING COUNT(orden.id) >= 3;

-- CONSULTA 3
-- Promedio de venta por producto en 2026
SELECT
  producto.nombre AS producto,
  AVG(orden.total) AS promedio_venta
FROM orden
INNER JOIN producto ON orden.producto_id = producto.id
WHERE YEAR(orden.fecha_orden) = 2026
GROUP BY producto.nombre;

-- CONSULTA 4
-- Órdenes con total mayor al promedio general en 2026
SELECT
  orden.id,
  cliente.nombre AS cliente,
  producto.nombre AS producto,
  orden.fecha_orden,
  orden.total
FROM orden
INNER JOIN cliente ON orden.cliente_id = cliente.id
INNER JOIN producto ON orden.producto_id = producto.id
WHERE YEAR(orden.fecha_orden) = 2026
  AND orden.total > (
    SELECT AVG(o2.total)
    FROM orden o2
    WHERE YEAR(o2.fecha_orden) = 2026
  )
ORDER BY orden.total DESC;

-- CONSULTA 5
-- Clientes con más órdenes que el promedio por cliente en 2026
SELECT
  t.cliente,
  t.total_ordenes
FROM (
  SELECT
    cliente.id,
    cliente.nombre AS cliente,
    COUNT(orden.id) AS total_ordenes
  FROM cliente
  INNER JOIN orden ON orden.cliente_id = cliente.id
  WHERE YEAR(orden.fecha_orden) = 2026
  GROUP BY cliente.id, cliente.nombre
) AS t
WHERE t.total_ordenes > (
  SELECT AVG(x.cant)
  FROM (
    SELECT COUNT(o3.id) AS cant
    FROM cliente c3
    INNER JOIN orden o3 ON o3.cliente_id = c3.id
    WHERE YEAR(o3.fecha_orden) = 2026
    GROUP BY c3.id
  ) AS x
);
