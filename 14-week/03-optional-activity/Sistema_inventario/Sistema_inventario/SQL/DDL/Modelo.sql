CREATE DATABASE enterprise_system;
use  enterprise_system;

-- Modulo de Seguridad y Control de Acceso--
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permisos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    modulo VARCHAR(100),
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE
);

CREATE TABLE rol_permisos (
    id SERIAL PRIMARY KEY,
    rol_id INT REFERENCES roles(id),
    permiso_id INT REFERENCES permisos(id),
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    telefono VARCHAR(30),
    rol_id INT REFERENCES roles(id),
    estado BOOLEAN DEFAULT TRUE,
    ultimo_login TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sesiones (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    token TEXT NOT NULL,
    ip VARCHAR(100),
    dispositivo VARCHAR(150),
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    estado BOOLEAN DEFAULT TRUE
);

CREATE TABLE tokens_recuperacion (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    token TEXT UNIQUE NOT NULL,
    fecha_expiracion TIMESTAMP,
    usado BOOLEAN DEFAULT FALSE
);

CREATE TABLE logs_login (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    email_intentado VARCHAR(150),
    ip VARCHAR(100),
    exitoso BOOLEAN,
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auditoria_seguridad (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    accion VARCHAR(200),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Modulo de Usuarios--
CREATE TABLE estados_usuario (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE perfiles_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id INT UNIQUE REFERENCES usuarios(id),
    foto_perfil TEXT,
    fecha_nacimiento DATE,
    genero VARCHAR(30),
    direccion TEXT,
    biografia TEXT,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE configuraciones_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    idioma VARCHAR(20) DEFAULT 'es',
    tema VARCHAR(20) DEFAULT 'light',
    recibir_notificaciones BOOLEAN DEFAULT TRUE,
    zona_horaria VARCHAR(50)
);

CREATE TABLE actividad_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    accion VARCHAR(200),
    modulo VARCHAR(100),
    descripcion TEXT,
    ip VARCHAR(100),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios_empleados (
    id SERIAL PRIMARY KEY,
    usuario_id INT UNIQUE REFERENCES usuarios(id),
    empleado_id INT UNIQUE
);

--Modulo de clientes--
CREATE TABLE paises (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE departamentos (
    id SERIAL PRIMARY KEY,
    pais_id INT REFERENCES paises(id),
    nombre VARCHAR(100)
);

CREATE TABLE ciudades (
    id SERIAL PRIMARY KEY,
    departamento_id INT REFERENCES departamentos(id),
    nombre VARCHAR(100)
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(30),
    email VARCHAR(150),
    direccion TEXT,
    ciudad_id INT REFERENCES ciudades(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tipos_cliente (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descuento NUMERIC(5,2)
);

CREATE TABLE cliente_tipo (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    tipo_id INT REFERENCES tipos_cliente(id)
);

CREATE TABLE direcciones_cliente (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    direccion TEXT,
    ciudad_id INT REFERENCES ciudades(id)
);

CREATE TABLE historial_clientes (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    cambio TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modulo de Productos--
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE subcategorias (
    id SERIAL PRIMARY KEY,
    categoria_id INT REFERENCES categorias(id),
    nombre VARCHAR(100),
    descripcion TEXT
);

CREATE TABLE marcas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(12,2),
    stock INT DEFAULT 0,
    marca_id INT REFERENCES marcas(id),
    subcategoria_id INT REFERENCES subcategorias(id),
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE imagenes_producto (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    url TEXT
);

CREATE TABLE atributos_producto (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    nombre VARCHAR(100),
    valor VARCHAR(255)
);

CREATE TABLE historial_precios (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    precio_anterior NUMERIC(12,2),
    precio_nuevo NUMERIC(12,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE codigos_barras (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    codigo VARCHAR(100) UNIQUE
);

CREATE TABLE etiquetas_producto (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    etiqueta VARCHAR(100)
);

--Modulo de Proveedores--
CREATE TABLE proveedores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150),
    telefono VARCHAR(30),
    email VARCHAR(150),
    direccion TEXT
);

CREATE TABLE producto_proveedor (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    proveedor_id INT REFERENCES proveedores(id)
);

CREATE TABLE contactos_proveedor (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    nombre VARCHAR(150),
    telefono VARCHAR(30),
    email VARCHAR(150)
);

CREATE TABLE contratos_proveedor (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    fecha_inicio DATE,
    fecha_fin DATE,
    descripcion TEXT
);

CREATE TABLE pagos_proveedor (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    monto NUMERIC(12,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Modulo de Inventario--
CREATE TABLE almacenes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    ubicacion TEXT
);

CREATE TABLE inventario (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    almacen_id INT REFERENCES almacenes(id),
    cantidad INT DEFAULT 0
);

CREATE TABLE movimientos_inventario (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    tipo VARCHAR(50),
    cantidad INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lotes (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    numero_lote VARCHAR(100),
    fecha_vencimiento DATE
);

CREATE TABLE ajustes_inventario (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    motivo TEXT,
    cantidad INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transferencias (
    id SERIAL PRIMARY KEY,
    origen_id INT REFERENCES almacenes(id),
    destino_id INT REFERENCES almacenes(id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--Modulo de Compras--
CREATE TABLE compras (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(12,2)
);

CREATE TABLE detalle_compras (
    id SERIAL PRIMARY KEY,
    compra_id INT REFERENCES compras(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT,
    precio NUMERIC(12,2)
);

CREATE TABLE ordenes_compra (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    estado VARCHAR(50),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recepcion_compras (
    id SERIAL PRIMARY KEY,
    compra_id INT REFERENCES compras(id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devoluciones_compra (
    id SERIAL PRIMARY KEY,
    compra_id INT REFERENCES compras(id),
    motivo TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--Modulo de Ventas--
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    usuario_id INT REFERENCES usuarios(id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(12,2)
);

CREATE TABLE detalle_ventas (
    id SERIAL PRIMARY KEY,
    venta_id INT REFERENCES ventas(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT,
    precio NUMERIC(12,2)
);

CREATE TABLE facturas (
    id SERIAL PRIMARY KEY,
    venta_id INT REFERENCES ventas(id),
    numero_factura VARCHAR(100) UNIQUE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE metodos_pago (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100)
);

CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    venta_id INT REFERENCES ventas(id),
    metodo_pago_id INT REFERENCES metodos_pago(id),
    monto NUMERIC(12,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devoluciones_venta (
    id SERIAL PRIMARY KEY,
    venta_id INT REFERENCES ventas(id),
    motivo TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE carrito (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE carrito_items (
    id SERIAL PRIMARY KEY,
    carrito_id INT REFERENCES carrito(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT
);
--Modulo de RRHH--
CREATE TABLE cargos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150),
    telefono VARCHAR(30),
    email VARCHAR(150),
    cargo_id INT REFERENCES cargos(id),
    salario NUMERIC(12,2)
);

CREATE TABLE nomina (
    id SERIAL PRIMARY KEY,
    empleado_id INT REFERENCES empleados(id),
    salario NUMERIC(12,2),
    fecha_pago DATE
);

CREATE TABLE asistencia (
    id SERIAL PRIMARY KEY,
    empleado_id INT REFERENCES empleados(id),
    fecha DATE,
    estado VARCHAR(50)
);

CREATE TABLE vacaciones (
    id SERIAL PRIMARY KEY,
    empleado_id INT REFERENCES empleados(id),
    fecha_inicio DATE,
    fecha_fin DATE
);
-- Modulo de Reportes--
CREATE TABLE reportes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE estadisticas (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(100),
    valor NUMERIC(12,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dashboards (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT
);

-- Auditoria y Logs--
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    accion VARCHAR(200),
    tabla_afectada VARCHAR(100),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE logs_sistema (
    id SERIAL PRIMARY KEY,
    nivel VARCHAR(50),
    mensaje TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);