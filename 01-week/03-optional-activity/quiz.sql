-- ============================================================================
-- SCRIPT: Sistema de Gestión de Facturas y Control de Acceso
-- Motor: MySQL 5.7+
-- ============================================================================

-- Limpiar base de datos previa (opcional)
DROP DATABASE IF EXISTS facturacion_db;
CREATE DATABASE facturacion_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE facturacion_db;

-- ============================================================================
-- DDL: DEFINICIÓN DE ESTRUCTURAS
-- ============================================================================

-- Tabla: PERSON (base de usuarios y entidades)
CREATE TABLE person (
  id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  phone VARCHAR(20),
  address VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(10),
  country VARCHAR(100) DEFAULT 'Colombia',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: MODULE (módulos del sistema)
CREATE TABLE module (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  code VARCHAR(50) UNIQUE NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: ROLE (roles del sistema)
CREATE TABLE role (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: PERMISSION (permisos del sistema)
CREATE TABLE permission (
  id INT PRIMARY KEY AUTO_INCREMENT,
  module_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  code VARCHAR(100) NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (module_id) REFERENCES module(id) ON DELETE CASCADE,
  UNIQUE KEY uk_module_code (module_id, code),
  INDEX idx_module_id (module_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: USER (usuarios del sistema)
CREATE TABLE user (
  id INT PRIMARY KEY AUTO_INCREMENT,
  person_id INT NOT NULL UNIQUE,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role_id INT NOT NULL,
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  last_login TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (person_id) REFERENCES person(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE RESTRICT,
  INDEX idx_username (username),
  INDEX idx_role_id (role_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: PRODUCT_CATEGORY (categorías de productos)
CREATE TABLE product_category (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: PRODUCT (catálogo de productos)
CREATE TABLE product (
  id INT PRIMARY KEY AUTO_INCREMENT,
  category_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  description VARCHAR(500),
  sku VARCHAR(50) UNIQUE NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
  stock_quantity INT DEFAULT 0,
  status ENUM('active', 'inactive', 'discontinued') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES product_category(id) ON DELETE RESTRICT,
  INDEX idx_category_id (category_id),
  INDEX idx_sku (sku),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: BILL (facturas)
CREATE TABLE bill (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bill_number VARCHAR(50) UNIQUE NOT NULL,
  user_id INT NOT NULL,
  bill_date DATE NOT NULL,
  due_date DATE,
  total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'issued', 'paid', 'cancelled') DEFAULT 'draft',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE RESTRICT,
  INDEX idx_bill_number (bill_number),
  INDEX idx_user_id (user_id),
  INDEX idx_bill_date (bill_date),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: BILL_DETAIL (detalles de factura)
CREATE TABLE bill_detail (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bill_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
  line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  discount_percent DECIMAL(5, 2) DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  discount_amount DECIMAL(12, 2) GENERATED ALWAYS AS (line_total * discount_percent / 100) STORED,
  net_total DECIMAL(12, 2) GENERATED ALWAYS AS (line_total - discount_amount) STORED,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (bill_id) REFERENCES bill(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE RESTRICT,
  INDEX idx_bill_id (bill_id),
  INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DML: INSERCIÓN DE DATOS SINTÉTICOS
-- ============================================================================

-- INSERTAR MÓDULOS (2 módulos)
INSERT INTO module (name, description, code, status) VALUES
('Facturación', 'Módulo de generación y gestión de facturas', 'BILLING', 'active'),
('Control de Acceso', 'Módulo de usuarios y permisos', 'ACCESS', 'active');

-- INSERTAR ROLES (3+ roles)
INSERT INTO role (name, description, status) VALUES
('Administrador', 'Acceso total al sistema', 'active'),
('Gerente de Ventas', 'Gestión de facturas y reportes', 'active'),
('Vendedor', 'Creación y seguimiento de facturas', 'active'),
('Auditor', 'Lectura de reportes y auditoría', 'active');

-- INSERTAR PERMISOS (asociados a módulos)
INSERT INTO permission (module_id, name, description, code, status) VALUES
(1, 'Crear Factura', 'Permiso para crear nuevas facturas', 'BILL_CREATE', 'active'),
(1, 'Editar Factura', 'Permiso para editar facturas existentes', 'BILL_EDIT', 'active'),
(1, 'Eliminar Factura', 'Permiso para eliminar facturas', 'BILL_DELETE', 'active'),
(1, 'Ver Facturas', 'Permiso para consultar facturas', 'BILL_READ', 'active'),
(2, 'Gestionar Usuarios', 'Permiso para crear y modificar usuarios', 'USER_MANAGE', 'active'),
(2, 'Gestionar Roles', 'Permiso para crear y modificar roles', 'ROLE_MANAGE', 'active'),
(2, 'Ver Usuarios', 'Permiso para consultar usuarios', 'USER_READ', 'active'),
(2, 'Gestionar Permisos', 'Permiso para asignar permisos a roles', 'PERM_MANAGE', 'active');

-- INSERTAR PERSONAS (20 personas)
INSERT INTO person (first_name, last_name, email, phone, address, city, state, postal_code, country) VALUES
('Carlos', 'Rodríguez', 'carlos.rodriguez@empresa.com', '+573001234567', 'Cra 7 #45-23', 'Bogotá', 'DC', '110221', 'Colombia'),
('María', 'García', 'maria.garcia@empresa.com', '+573012345678', 'Cra 10 #50-40', 'Bogotá', 'DC', '110230', 'Colombia'),
('Juan', 'Martínez', 'juan.martinez@empresa.com', '+573023456789', 'Cra 15 #60-50', 'Bogotá', 'DC', '110240', 'Colombia'),
('Ana', 'López', 'ana.lopez@empresa.com', '+573034567890', 'Cra 20 #70-60', 'Bogotá', 'DC', '110250', 'Colombia'),
('Pedro', 'Sánchez', 'pedro.sanchez@empresa.com', '+573045678901', 'Cra 25 #80-70', 'Bogotá', 'DC', '110260', 'Colombia'),
('Laura', 'Fernández', 'laura.fernandez@empresa.com', '+573056789012', 'Cra 30 #90-80', 'Bogotá', 'DC', '110270', 'Colombia'),
('Jorge', 'Pérez', 'jorge.perez@empresa.com', '+573067890123', 'Cra 35 #100-90', 'Bogotá', 'DC', '110280', 'Colombia'),
('Claudia', 'Morales', 'claudia.morales@empresa.com', '+573078901234', 'Cra 40 #110-100', 'Bogotá', 'DC', '110290', 'Colombia'),
('Roberto', 'Jiménez', 'roberto.jimenez@empresa.com', '+573089012345', 'Cra 45 #120-110', 'Bogotá', 'DC', '110300', 'Colombia'),
('Sofía', 'Díaz', 'sofia.diaz@empresa.com', '+573090123456', 'Cra 50 #130-120', 'Bogotá', 'DC', '110310', 'Colombia'),
('Felipe', 'Castillo', 'felipe.castillo@empresa.com', '+573001112222', 'Cra 55 #140-130', 'Medellín', 'Antioquia', '050001', 'Colombia'),
('Alejandra', 'Rojas', 'alejandra.rojas@empresa.com', '+573012223333', 'Cra 60 #150-140', 'Medellín', 'Antioquia', '050002', 'Colombia'),
('Diego', 'Herrera', 'diego.herrera@empresa.com', '+573023334444', 'Cra 65 #160-150', 'Cali', 'Valle', '760001', 'Colombia'),
('Natalia', 'Vargas', 'natalia.vargas@empresa.com', '+573034445555', 'Cra 70 #170-160', 'Cali', 'Valle', '760002', 'Colombia'),
('Gustavo', 'Ruiz', 'gustavo.ruiz@empresa.com', '+573045556666', 'Cra 75 #180-170', 'Barranquilla', 'Atlántico', '080001', 'Colombia'),
('Valeria', 'Ocampo', 'valeria.ocampo@empresa.com', '+573056667777', 'Cra 80 #190-180', 'Barranquilla', 'Atlántico', '080002', 'Colombia'),
('Andrés', 'Medina', 'andres.medina@empresa.com', '+573067778888', 'Cra 85 #200-190', 'Bucaramanga', 'Santander', '680001', 'Colombia'),
('Isabela', 'Santos', 'isabela.santos@empresa.com', '+573078889999', 'Cra 90 #210-200', 'Bucaramanga', 'Santander', '680002', 'Colombia'),
('Marcos', 'Avila', 'marcos.avila@empresa.com', '+573089990000', 'Cra 95 #220-210', 'Bogotá', 'DC', '110320', 'Colombia'),
('Patricia', 'Reyes', 'patricia.reyes@empresa.com', '+573090001111', 'Cra 100 #230-220', 'Bogotá', 'DC', '110330', 'Colombia');

-- INSERTAR USUARIOS (basados en personas)
INSERT INTO user (person_id, username, password_hash, role_id, status) VALUES
(1, 'admin_carlos', 'hash_secure_12345678901', 1, 'active'),
(2, 'maria_ventas', 'hash_secure_23456789012', 2, 'active'),
(3, 'juan_vendedor', 'hash_secure_34567890123', 3, 'active'),
(4, 'ana_vendedor', 'hash_secure_45678901234', 3, 'active'),
(5, 'pedro_auditor', 'hash_secure_56789012345', 4, 'active'),
(6, 'laura_gerente', 'hash_secure_67890123456', 2, 'active'),
(7, 'jorge_vendedor', 'hash_secure_78901234567', 3, 'active'),
(8, 'claudia_admin', 'hash_secure_89012345678', 1, 'active'),
(9, 'roberto_vendedor', 'hash_secure_90123456789', 3, 'active'),
(10, 'sofia_gerente', 'hash_secure_01234567890', 2, 'active'),
(11, 'felipe_vendedor', 'hash_secure_11223344556', 3, 'active'),
(12, 'alejandra_auditor', 'hash_secure_22334455667', 4, 'active'),
(13, 'diego_vendedor', 'hash_secure_33445566778', 3, 'active'),
(14, 'natalia_gerente', 'hash_secure_44556677889', 2, 'active'),
(15, 'gustavo_vendedor', 'hash_secure_55667788990', 3, 'active'),
(16, 'valeria_admin', 'hash_secure_66778899001', 1, 'active'),
(17, 'andres_vendedor', 'hash_secure_77889900112', 3, 'active'),
(18, 'isabela_auditor', 'hash_secure_88990011223', 4, 'active'),
(19, 'marcos_vendedor', 'hash_secure_99001122334', 3, 'active'),
(20, 'patricia_gerente', 'hash_secure_00112233445', 2, 'active');

-- INSERTAR CATEGORÍAS DE PRODUCTOS (5 categorías)
INSERT INTO product_category (name, description, status) VALUES
('Electrónica', 'Productos electrónicos y dispositivos', 'active'),
('Informática', 'Equipos de cómputo y accesorios', 'active'),
('Software', 'Licencias de software y herramientas digitales', 'active'),
('Telecomunicaciones', 'Equipos y servicios de telecomunicaciones', 'active'),
('Accesorios Tecnológicos', 'Accesorios y repuestos para equipos', 'active');

-- INSERTAR PRODUCTOS (50 productos)
INSERT INTO product (category_id, name, description, sku, unit_price, stock_quantity, status) VALUES
-- Categoría 1: Electrónica (10 productos)
(1, 'Monitor LG 27" 4K', 'Monitor ultrawide 4K con entrada HDMI', 'MON-LG-27-4K', 450.00, 15, 'active'),
(1, 'Teclado Mecánico RGB', 'Teclado mecánico con retroiluminación RGB', 'KEY-RGB-MECH', 120.00, 25, 'active'),
(1, 'Mouse Logitech MX Master 3', 'Mouse inalámbrico de alta precisión', 'MOUSE-LGT-MX3', 99.99, 30, 'active'),
(1, 'Webcam Logitech C920', 'Webcam Full HD con micrófono integrado', 'WEB-LGT-C920', 79.99, 20, 'active'),
(1, 'Headset Corsair Void Pro', 'Headset gamer con sonido envolvente', 'HEAD-VOID-PRO', 129.99, 18, 'active'),
(1, 'Cable HDMI 2.1', 'Cable HDMI 4K@120Hz de 2 metros', 'CABLE-HDMI-2.1', 24.99, 50, 'active'),
(1, 'Adaptador USB-C', 'Adaptador multipuerto USB-C', 'ADAPT-USB-C', 34.99, 40, 'active'),
(1, 'Hub USB 3.0', 'Hub USB 3.0 de 7 puertos', 'HUB-USB-7PORT', 49.99, 22, 'active'),
(1, 'Funda para Laptop', 'Funda protectora para laptop 15.6"', 'FUNDA-LAP-15', 29.99, 35, 'active'),
(1, 'Soporte de Laptop', 'Soporte ajustable para laptop', 'SOPORTE-LAP-ADJ', 39.99, 28, 'active'),
-- Categoría 2: Informática (12 productos)
(2, 'SSD Samsung 970 EVO 500GB', 'Unidad SSD NVMe de 500GB', 'SSD-SAM-970-500', 59.99, 45, 'active'),
(2, 'Memoria RAM Corsair 16GB', 'Memoria RAM DDR4 3200MHz 16GB', 'RAM-CORS-16GB', 69.99, 38, 'active'),
(2, 'Procesador AMD Ryzen 5 5600X', 'Procesador Ryzen 5600X 6 núcleos', 'CPU-AMD-5600X', 199.99, 12, 'active'),
(2, 'Motherboard ASUS B550', 'Placa madre ASUS B550-E Gaming', 'MOBO-ASUS-B550', 179.99, 10, 'active'),
(2, 'Fuente de Poder Corsair 750W', 'Fuente modular 750W 80+ Gold', 'PSU-CORS-750W', 119.99, 20, 'active'),
(2, 'Disipador CPU Noctua NH-D15', 'Disipador de aire de doble torre', 'COOLER-NOCT-D15', 89.99, 15, 'active'),
(2, 'Carcasa Fractal Design Core 1000', 'Case ATX compacta', 'CASE-FRAC-C1000', 49.99, 18, 'active'),
(2, 'Monitor ASUS ProArt 32"', 'Monitor profesional 4K 32"', 'MON-ASUS-32PRO', 699.99, 5, 'active'),
(2, 'GPU NVIDIA RTX 3060', 'Tarjeta gráfica NVIDIA RTX 3060 12GB', 'GPU-RTX-3060', 329.99, 8, 'active'),
(2, 'Laptop Dell XPS 13', 'Laptop ultraportátil 13" FHD', 'LAP-DELL-XPS13', 999.99, 6, 'active'),
(2, 'PC Gaming ASUS TUF', 'PC gaming prearmado', 'PC-ASUS-TUF', 1299.99, 4, 'active'),
(2, 'Monitor Gaming Acer 144Hz', 'Monitor 27" 1440p 144Hz', 'MON-ACER-144HZ', 349.99, 11, 'active'),
-- Categoría 3: Software (12 productos)
(3, 'Windows 11 Pro', 'Licencia de Windows 11 Pro', 'WIN-11-PRO', 199.99, 25, 'active'),
(3, 'Microsoft Office 365', 'Suscripción Office 365 anual', 'OFFICE-365', 69.99, 30, 'active'),
(3, 'Adobe Creative Cloud', 'Suscripción Adobe CC anual', 'ADOBE-CC', 599.99, 10, 'active'),
(3, 'Antivirus Norton 360', 'Licencia Norton 360 anual', 'AV-NORTON-360', 49.99, 40, 'active'),
(3, 'JetBrains IntelliJ IDEA', 'Licencia IntelliJ IDEA anual', 'IDE-INTELLIJ', 199.99, 15, 'active'),
(3, 'Sublime Text 4', 'Licencia Sublime Text 4', 'EDITOR-SUBLIME', 99.99, 20, 'active'),
(3, 'Visual Studio Professional', 'Licencia Visual Studio Professional', 'VS-PROFESSIONAL', 299.99, 12, 'active'),
(3, 'Slack Pro', 'Suscripción Slack Pro anual', 'SLACK-PRO', 120.00, 35, 'active'),
(3, 'Zoom Pro', 'Licencia Zoom Pro anual', 'ZOOM-PRO', 159.99, 28, 'active'),
(3, 'GitHub Copilot', 'Suscripción GitHub Copilot anual', 'GH-COPILOT', 100.00, 22, 'active'),
(3, 'Figma Professional', 'Suscripción Figma Professional anual', 'FIGMA-PRO', 144.00, 18, 'active'),
(3, 'DataGrip', 'Licencia DataGrip anual', 'DATAGRIP-LIC', 149.99, 14, 'active'),
-- Categoría 4: Telecomunicaciones (10 productos)
(4, 'Router WiFi 6 ASUS', 'Router WiFi 6 de 4 antenas', 'ROUTER-AX3000', 89.99, 25, 'active'),
(4, 'Modem DOCSIS 3.1', 'Modem DOCSIS 3.1 para internet', 'MODEM-DOC31', 109.99, 18, 'active'),
(4, 'Switch de Red Cisco 24 puertos', 'Switch gestionado 24 puertos Gigabit', 'SWITCH-CISCO-24', 299.99, 8, 'active'),
(4, 'Cable Cat6 100m', 'Cable de red Cat6 100 metros', 'CABLE-CAT6-100M', 39.99, 50, 'active'),
(4, 'Firewall FortiGate 30E', 'Firewall de seguridad empresarial', 'FW-FORTGATE-30', 499.99, 5, 'active'),
(4, 'SIP Phone Cisco 7940', 'Teléfono IP Cisco 7940', 'PHONE-CISCO-7940', 179.99, 12, 'active'),
(4, 'Access Point Ubiquiti UAP-AC', 'Access point WiFi AC', 'AP-UBIQ-AC', 129.99, 20, 'active'),
(4, 'NAS Synology 4 bahías', 'Servidor NAS 4 bahías', 'NAS-SYNOLOGY-4', 349.99, 7, 'active'),
(4, 'Módulo SFP+ 10G', 'Módulo transceptor SFP+ 10 Gigabit', 'SFP-PLUS-10G', 89.99, 15, 'active'),
(4, 'Antena WiFi Omnidireccional', 'Antena WiFi 9dBi omnidireccional', 'ANT-WIFI-9DBi', 24.99, 30, 'active'),
-- Categoría 5: Accesorios Tecnológicos (6 productos)
(5, 'Pasta Térmica Thermal Grizzly', 'Pasta térmica de alta conductividad', 'PASTA-THERMAL-1G', 14.99, 60, 'active'),
(5, 'Protector de Pantalla Vidrio Templado', 'Protector de pantalla 15.6"', 'PROTECT-GLASS-15', 19.99, 40, 'active'),
(5, 'Limpiador de Pantalla Isopropílico', 'Solución limpiadora para pantallas', 'CLEANER-ISOP-500', 9.99, 50, 'active'),
(5, 'Pasta Desmontable', 'Pasta para retirada de componentes', 'PASTE-REMOVE', 12.99, 35, 'active'),
(5, 'Aislante de Cable', 'Cinta aislante de PVC', 'TAPE-PVC-20M', 5.99, 100, 'active'),
(5, 'Kit de Limpieza Profesional', 'Kit completo de limpieza para equipos', 'CLEAN-KIT-PRO', 34.99, 25, 'active');

-- INSERTAR FACTURAS (5 facturas)
INSERT INTO bill (bill_number, user_id, bill_date, due_date, total_amount, status, notes) VALUES
('FAC-2024-001', 1, '2024-01-15', '2024-02-15', 0.00, 'draft', 'Venta a cliente corporativo'),
('FAC-2024-002', 2, '2024-01-20', '2024-02-20', 0.00, 'issued', 'Equipo de home office'),
('FAC-2024-003', 6, '2024-01-25', '2024-02-25', 0.00, 'paid', 'Licencias de software'),
('FAC-2024-004', 10, '2024-02-01', '2024-03-01', 0.00, 'issued', 'Componentes electrónicos'),
('FAC-2024-005', 14, '2024-02-10', '2024-03-10', 0.00, 'draft', 'Infraestructura de red');

-- INSERTAR DETALLES DE FACTURA (múltiples productos por factura)
-- FAC-2024-001: 5 productos
INSERT INTO bill_detail (bill_id, product_id, quantity, unit_price, discount_percent) VALUES
(1, 1, 2, 450.00, 10.00),
(1, 2, 3, 120.00, 5.00),
(1, 5, 2, 129.99, 0.00),
(1, 11, 5, 59.99, 8.00),
(1, 15, 1, 199.99, 0.00);

-- FAC-2024-002: 7 productos
INSERT INTO bill_detail (bill_id, product_id, quantity, unit_price, discount_percent) VALUES
(2, 3, 1, 99.99, 0.00),
(2, 4, 1, 79.99, 5.00),
(2, 7, 2, 34.99, 10.00),
(2, 9, 2, 29.99, 0.00),
(2, 10, 1, 39.99, 0.00),
(2, 18, 1, 69.99, 0.00),
(2, 20, 1, 999.99, 15.00);

-- FAC-2024-003: 6 productos
INSERT INTO bill_detail (bill_id, product_id, quantity, unit_price, discount_percent) VALUES
(3, 15, 10, 199.99, 20.00),
(3, 16, 5, 69.99, 10.00),
(3, 17, 2, 599.99, 0.00),
(3, 18, 3, 49.99, 5.00),
(3, 19, 1, 199.99, 0.00),
(3, 21, 1, 299.99, 12.00);

-- FAC-2024-004: 8 productos
INSERT INTO bill_detail (bill_id, product_id, quantity, unit_price, discount_percent) VALUES
(4, 12, 8, 59.99, 15.00),
(4, 13, 10, 69.99, 10.00),
(4, 14, 1, 199.99, 0.00),
(4, 15, 1, 179.99, 0.00),
(4, 16, 1, 119.99, 5.00),
(4, 17, 2, 89.99, 0.00),
(4, 18, 1, 49.99, 0.00),
(4, 45, 5, 14.99, 0.00);  -- ✅ FIX: antes estaba 57 (no existe)

-- FAC-2024-005: 4 productos
INSERT INTO bill_detail (bill_id, product_id, quantity, unit_price, discount_percent) VALUES
(5, 35, 1, 89.99, 5.00),
(5, 36, 1, 109.99, 0.00),
(5, 37, 1, 299.99, 10.00),
(5, 40, 2, 129.99, 0.00);

-- ============================================================================
-- ACTUALIZAR TOTALES DE FACTURAS (basado en detalles)
-- ============================================================================

UPDATE bill b SET b.total_amount = (
  SELECT COALESCE(SUM(bd.net_total), 0)
  FROM bill_detail bd
  WHERE bd.bill_id = b.id
);

-- ============================================================================
-- VERIFICACIÓN DE INTEGRIDAD REFERENCIAL
-- ============================================================================

SELECT 'RESUMEN DE DATOS' AS section;
SELECT COUNT(*) AS total_personas FROM person;
SELECT COUNT(*) AS total_usuarios FROM user;
SELECT COUNT(*) AS total_roles FROM role;
SELECT COUNT(*) AS total_modulos FROM module;
SELECT COUNT(*) AS total_permisos FROM permission;
SELECT COUNT(*) AS total_categorias FROM product_category;
SELECT COUNT(*) AS total_productos FROM product;
SELECT COUNT(*) AS total_facturas FROM bill;
SELECT COUNT(*) AS total_detalles_factura FROM bill_detail;

SELECT '\nDETALLE DE FACTURAS CREADAS' AS section;
SELECT 
  b.bill_number,
  u.username,
  b.bill_date,
  COUNT(bd.id) AS cantidad_items,
  b.total_amount,
  b.status
FROM bill b
JOIN user u ON b.user_id = u.id
LEFT JOIN bill_detail bd ON b.id = bd.bill_id
GROUP BY b.id, b.bill_number, u.username, b.bill_date, b.total_amount, b.status
ORDER BY b.bill_date DESC;

SELECT '\nPRODUCTOS CON MÁS STOCK' AS section;
SELECT 
  p.sku,
  p.name,
  pc.name AS categoria,
  p.stock_quantity,
  p.unit_price
FROM product p
JOIN product_category pc ON p.category_id = pc.id
ORDER BY p.stock_quantity DESC
LIMIT 10;

-- EJERCICIO 4: Facturas pendientes por usuario 

SELECT '\nEJERCICIO 4 - Variante 1 (JOIN directo)' AS section;

SELECT
  CONCAT(p.first_name, ' ', p.last_name) AS nombre_completo,
  p.email AS email_contacto,
  COUNT(b.id) AS facturas_pendientes,
  SUM(b.total_amount) AS monto_total_pendiente,
  MAX(b.total_amount) AS monto_maximo_factura,
  MIN(b.bill_date) AS fecha_mas_antigua_pendiente
FROM user u
INNER JOIN person p
  ON p.id = u.person_id
LEFT JOIN bill b
  ON b.user_id = u.id
WHERE u.status = 'active'
  AND b.status IN ('draft', 'issued')
GROUP BY
  u.id, p.first_name, p.last_name, p.email
HAVING COUNT(b.id) >= 1
ORDER BY monto_total_pendiente DESC;


SELECT '\nEJERCICIO 4 - Variante 2 (Subconsulta en FROM)' AS section;

SELECT
  CONCAT(p.first_name, ' ', p.last_name) AS nombre_completo,
  p.email AS email_contacto,
  bp.facturas_pendientes,
  bp.monto_total_pendiente,
  bp.monto_maximo_factura,
  bp.fecha_mas_antigua_pendiente
FROM user u
INNER JOIN person p
  ON p.id = u.person_id
INNER JOIN (
  SELECT
    user_id,
    COUNT(*) AS facturas_pendientes,
    SUM(total_amount) AS monto_total_pendiente,
    MAX(total_amount) AS monto_maximo_factura,
    MIN(bill_date) AS fecha_mas_antigua_pendiente
  FROM bill
  WHERE status IN ('draft', 'issued')
  GROUP BY user_id
) bp
  ON bp.user_id = u.id
WHERE u.status = 'active'
ORDER BY bp.monto_total_pendiente DESC;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

SELECT COUNT(*) AS total_facturas FROM bill;
SELECT bill_number, status, total_amount
FROM bill
WHERE status IN ('draft','issued');

