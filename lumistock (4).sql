-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 20-11-2026 a las 00:07:07
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `lumistock`
--
CREATE DATABASE IF NOT EXISTS `lumistock` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `lumistock`;

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `prueba_ajuste_cable` ()   BEGIN
    DECLARE filas INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE ubicacion_productos up
    INNER JOIN productos p
        ON up.id_producto = p.id_producto
    SET up.cantidad = 9
    WHERE p.codigo_producto = 'ELE001'
      AND up.id_ubicacion = 2
      AND up.cantidad = 10;

    SET filas = ROW_COUNT();

    IF filas <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'No se pudo realizar el ajuste';
    END IF;

    INSERT INTO movimientos_inventario
    (id_producto, id_ubicacion, id_usuario,
     tipo_movimiento, cantidad, observaciones)
    SELECT
        id_producto,
        2,
        1,
        'Ajuste',
        1,
        'Ajuste negativo: de 10 a 9 unidades'
    FROM productos
    WHERE codigo_producto = 'ELE001';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prueba_salida_cable` ()   BEGIN
    DECLARE filas INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE ubicacion_productos up
    INNER JOIN productos p
        ON up.id_producto = p.id_producto
    SET up.cantidad = up.cantidad - 3
    WHERE p.codigo_producto = 'ELE001'
      AND up.id_ubicacion = 2
      AND up.cantidad = 13;

    SET filas = ROW_COUNT();

    IF filas <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'No se pudo realizar la salida';
    END IF;

    INSERT INTO movimientos_inventario
    (id_producto, id_ubicacion, id_usuario,
     tipo_movimiento, cantidad, observaciones)
    SELECT
        id_producto,
        2,
        1,
        'Salida',
        3,
        'Salida de prueba de cable electrico'
    FROM productos
    WHERE codigo_producto = 'ELE001';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_salida_segura` (IN `p_codigo` VARCHAR(10), IN `p_ubicacion` INT, IN `p_usuario` INT, IN `p_cantidad` INT)   BEGIN
    DECLARE filas INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cantidad no valida';
    END IF;

    START TRANSACTION;

    UPDATE ubicacion_productos up
    INNER JOIN productos p
        ON up.id_producto = p.id_producto
    SET up.cantidad = up.cantidad - p_cantidad
    WHERE p.codigo_producto = p_codigo
      AND up.id_ubicacion = p_ubicacion
      AND up.cantidad >= p_cantidad;

    SET filas = ROW_COUNT();

    IF filas <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Existencias insuficientes o ubicacion no valida';
    END IF;

    INSERT INTO movimientos_inventario
    (id_producto, id_ubicacion, id_usuario,
     tipo_movimiento, cantidad, observaciones)
    SELECT
        id_producto,
        p_ubicacion,
        p_usuario,
        'Salida',
        p_cantidad,
        'Salida registrada con validacion'
    FROM productos
    WHERE codigo_producto = p_codigo;

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `descripcion` varchar(55) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `descripcion`) VALUES
(4, 'Accesorios'),
(3, 'Herramientas'),
(1, 'Iluminacion'),
(2, 'Material electrico');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `descripcion_estatus`
--

CREATE TABLE `descripcion_estatus` (
  `id_descripcion_estatus` int(11) NOT NULL,
  `descripcion_estatus` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `descripcion_estatus`
--

INSERT INTO `descripcion_estatus` (`id_descripcion_estatus`, `descripcion_estatus`) VALUES
(1, 'Buen Estado'),
(2, 'roto'),
(3, 'maltratado '),
(4, 'caducado '),
(5, 'revision ');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dispositivos_iot`
--

CREATE TABLE `dispositivos_iot` (
  `id_dispositivo` int(11) NOT NULL,
  `nombre_dispositivo` varchar(20) NOT NULL,
  `identificador` varchar(20) NOT NULL,
  `id_ubicacion` int(11) NOT NULL,
  `direccion_ip` varchar(45) DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT 1,
  `ultimo_contacto` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `dispositivos_iot`
--

INSERT INTO `dispositivos_iot` (`id_dispositivo`, `nombre_dispositivo`, `identificador`, `id_ubicacion`, `direccion_ip`, `estado`, `ultimo_contacto`) VALUES
(1, 'LED Pasillo A', 'IOT-A001', 1, '192.168.1.101', 1, '2026-11-04 23:40:12'),
(2, 'LED Pasillo B', 'IOT-B001', 3, '192.168.1.102', 1, '2026-11-04 23:40:12');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos_inventario`
--

CREATE TABLE `movimientos_inventario` (
  `id_movimiento` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `id_ubicacion` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `tipo_movimiento` enum('Entrada','Salida','Ajuste') NOT NULL,
  `cantidad` int(10) UNSIGNED NOT NULL,
  `fecha_movimiento` datetime NOT NULL DEFAULT current_timestamp(),
  `observaciones` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `movimientos_inventario`
--

INSERT INTO `movimientos_inventario` (`id_movimiento`, `id_producto`, `id_ubicacion`, `id_usuario`, `tipo_movimiento`, `cantidad`, `fecha_movimiento`, `observaciones`) VALUES
(1, 2, 2, 1, 'Entrada', 5, '2026-11-12 16:39:56', 'Regularizacion de entrada de prueba: 5 unidades'),
(2, 2, 2, 1, 'Salida', 3, '2026-11-12 16:52:04', 'Salida de prueba de cable electrico'),
(3, 2, 2, 1, 'Ajuste', 1, '2026-11-12 17:02:11', 'Ajuste negativo: de 10 a 9 unidades');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `codigo_producto` varchar(10) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `unidad_medida` varchar(30) NOT NULL,
  `estado_producto` varchar(30) NOT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `descripcion` text DEFAULT NULL,
  `id_categoria` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1,
  `stock_minimo` int(10) UNSIGNED NOT NULL DEFAULT 5,
  `imagen_producto` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `codigo_producto`, `nombre`, `unidad_medida`, `estado_producto`, `fecha_registro`, `descripcion`, `id_categoria`, `estatus`, `stock_minimo`, `imagen_producto`) VALUES
(1, 'LUM001', 'Foco LED 9W', 'Pieza', 'Nuevo', '2026-11-04 23:30:47', 'Foco LED de luz blanca', 1, 1, 10, 'imagenes/productos/foco_led.jpg'),
(2, 'ELE001', 'Cable electrico', 'Metro', 'Nuevo', '2026-11-04 23:30:47', 'Cable para instalaciones electricas', 2, 1, 10, 'imagenes/productos/cable_electrico.jpg'),
(3, 'HER001', 'Desarmador', 'Pieza', 'Nuevo', '2026-11-04 23:30:47', 'Desarmador de cruz', 3, 1, 5, 'imagenes/productos/desarmador.jpg'),
(4, 'ACC001', 'Cinta aislante', 'Pieza', 'Nuevo', '2026-11-04 23:30:47', 'Cinta para aislamiento electrico', 4, 2, 10, 'imagenes/productos/cinta_aislante.jpg');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `id_rol` int(11) NOT NULL,
  `tipo_rol` varchar(25) NOT NULL,
  `descripcion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`id_rol`, `tipo_rol`, `descripcion`) VALUES
(1, 'Administrador', 'Acceso completo al sistema'),
(2, 'Empleado', 'Acceso a operaciones del almacen');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ubicaciones`
--

CREATE TABLE `ubicaciones` (
  `id_ubicacion` int(11) NOT NULL,
  `pasillo` varchar(10) NOT NULL,
  `estante` varchar(10) NOT NULL,
  `nivel` int(11) NOT NULL,
  `posicion` varchar(10) NOT NULL,
  `descripcion` varchar(55) DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ubicaciones`
--

INSERT INTO `ubicaciones` (`id_ubicacion`, `pasillo`, `estante`, `nivel`, `posicion`, `descripcion`, `estado`) VALUES
(1, 'A', 'E1', 1, 'P1', 'Zona de iluminacion', 1),
(2, 'A', 'E1', 2, 'P2', 'Zona de material electrico', 1),
(3, 'B', 'E2', 1, 'P1', 'Zona de herramientas', 1),
(4, 'B', 'E2', 2, 'P2', 'Zona de accesorios', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ubicacion_productos`
--

CREATE TABLE `ubicacion_productos` (
  `id_ubicacion_producto` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `id_ubicacion` int(11) NOT NULL,
  `cantidad` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ubicacion_productos`
--

INSERT INTO `ubicacion_productos` (`id_ubicacion_producto`, `id_producto`, `id_ubicacion`, `cantidad`) VALUES
(1, 1, 1, 35),
(2, 2, 2, 9),
(3, 3, 3, 0),
(4, 4, 4, 20);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `contrasena` varchar(255) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre`, `contrasena`, `id_rol`, `estado`, `fecha_registro`) VALUES
(1, 'Administrador LumiStock', '$2y$10$ExeP6soK3hR4OivPJYzllOg6fZ/opayTfewuEpdNy.eOMuKhcOUoK', 1, 1, '2026-11-04 23:45:09'),
(2, 'Empleado LumiStock', '$2y$10$OXswvVIX5uv7Y6WFYqkrW.uViMEekrvGLdhlRNAdfEWdcP8XDQaJq', 2, 1, '2026-11-04 23:45:10');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_alertas_stock`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_alertas_stock` (
`id_producto` int(11)
,`codigo_producto` varchar(10)
,`producto` varchar(50)
,`existencias` decimal(32,0)
,`stock_minimo` int(10) unsigned
,`alerta` varchar(10)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_dashboard`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_dashboard` (
`total_productos` bigint(21)
,`productos_en_stock` bigint(21)
,`productos_criticos` bigint(21)
,`ubicaciones_activas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_productos_admin`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_productos_admin` (
`id_producto` int(11)
,`codigo_producto` varchar(10)
,`producto` varchar(50)
,`categoria` varchar(55)
,`imagen_producto` varchar(255)
,`unidad_medida` varchar(30)
,`condicion` varchar(50)
,`existencias` decimal(32,0)
,`stock_minimo` int(10) unsigned
,`alerta` varchar(10)
,`ubicacion` longtext
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_alertas_stock`
--
DROP TABLE IF EXISTS `vista_alertas_stock`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_alertas_stock`  AS SELECT `p`.`id_producto` AS `id_producto`, `p`.`codigo_producto` AS `codigo_producto`, `p`.`nombre` AS `producto`, coalesce(sum(`up`.`cantidad`),0) AS `existencias`, `p`.`stock_minimo` AS `stock_minimo`, CASE WHEN coalesce(sum(`up`.`cantidad`),0) = 0 THEN 'Agotado' WHEN coalesce(sum(`up`.`cantidad`),0) <= `p`.`stock_minimo` THEN 'Stock bajo' ELSE 'Disponible' END AS `alerta` FROM (`productos` `p` left join `ubicacion_productos` `up` on(`p`.`id_producto` = `up`.`id_producto`)) GROUP BY `p`.`id_producto`, `p`.`codigo_producto`, `p`.`nombre`, `p`.`stock_minimo` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_dashboard`
--
DROP TABLE IF EXISTS `vista_dashboard`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_dashboard`  AS SELECT (select count(0) from `productos`) AS `total_productos`, (select count(0) from `vista_alertas_stock` where `vista_alertas_stock`.`existencias` > 0) AS `productos_en_stock`, (select count(0) from `vista_alertas_stock` where `vista_alertas_stock`.`alerta` in ('Stock bajo','Agotado')) AS `productos_criticos`, (select count(0) from `ubicaciones` where `ubicaciones`.`estado` = 1) AS `ubicaciones_activas` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_productos_admin`
--
DROP TABLE IF EXISTS `vista_productos_admin`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_productos_admin`  AS SELECT `p`.`id_producto` AS `id_producto`, `p`.`codigo_producto` AS `codigo_producto`, `p`.`nombre` AS `producto`, `c`.`descripcion` AS `categoria`, `p`.`imagen_producto` AS `imagen_producto`, `p`.`unidad_medida` AS `unidad_medida`, `e`.`descripcion_estatus` AS `condicion`, `v`.`existencias` AS `existencias`, `p`.`stock_minimo` AS `stock_minimo`, `v`.`alerta` AS `alerta`, coalesce(`u`.`ubicaciones`,'Sin ubicación') AS `ubicacion` FROM ((((`productos` `p` join `categorias` `c` on(`p`.`id_categoria` = `c`.`id_categoria`)) join `descripcion_estatus` `e` on(`p`.`estatus` = `e`.`id_descripcion_estatus`)) left join `vista_alertas_stock` `v` on(`p`.`id_producto` = `v`.`id_producto`)) left join (select `up`.`id_producto` AS `id_producto`,group_concat(distinct concat('Pasillo ',`ub`.`pasillo`,', Estante ',`ub`.`estante`,', Nivel ',`ub`.`nivel`,', Posición ',`ub`.`posicion`) separator ' | ') AS `ubicaciones` from (`ubicacion_productos` `up` join `ubicaciones` `ub` on(`up`.`id_ubicacion` = `ub`.`id_ubicacion`)) group by `up`.`id_producto`) `u` on(`p`.`id_producto` = `u`.`id_producto`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`),
  ADD UNIQUE KEY `uq_descripcion` (`descripcion`);

--
-- Indices de la tabla `descripcion_estatus`
--
ALTER TABLE `descripcion_estatus`
  ADD PRIMARY KEY (`id_descripcion_estatus`);

--
-- Indices de la tabla `dispositivos_iot`
--
ALTER TABLE `dispositivos_iot`
  ADD PRIMARY KEY (`id_dispositivo`),
  ADD UNIQUE KEY `uq_identificador` (`identificador`),
  ADD KEY `fk_dispositivos_ubicacion` (`id_ubicacion`);

--
-- Indices de la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  ADD PRIMARY KEY (`id_movimiento`),
  ADD KEY `fk_mov_producto` (`id_producto`),
  ADD KEY `fk_mov_ubicacion` (`id_ubicacion`),
  ADD KEY `fk_mov_usuario` (`id_usuario`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `uq_codigo_producto` (`codigo_producto`),
  ADD KEY `fk_productos_categoria` (`id_categoria`),
  ADD KEY `fk_productos_estatus` (`estatus`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `uq_tipo_rol` (`tipo_rol`);

--
-- Indices de la tabla `ubicaciones`
--
ALTER TABLE `ubicaciones`
  ADD PRIMARY KEY (`id_ubicacion`),
  ADD UNIQUE KEY `uq_ubicacion_fisica` (`pasillo`,`estante`,`nivel`,`posicion`);

--
-- Indices de la tabla `ubicacion_productos`
--
ALTER TABLE `ubicacion_productos`
  ADD PRIMARY KEY (`id_ubicacion_producto`),
  ADD UNIQUE KEY `uq_producto_ubicacion` (`id_producto`,`id_ubicacion`),
  ADD KEY `fk_ubicacion_almacen` (`id_ubicacion`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `fk_usuarios_rol` (`id_rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `descripcion_estatus`
--
ALTER TABLE `descripcion_estatus`
  MODIFY `id_descripcion_estatus` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `dispositivos_iot`
--
ALTER TABLE `dispositivos_iot`
  MODIFY `id_dispositivo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  MODIFY `id_movimiento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `ubicaciones`
--
ALTER TABLE `ubicaciones`
  MODIFY `id_ubicacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `ubicacion_productos`
--
ALTER TABLE `ubicacion_productos`
  MODIFY `id_ubicacion_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `dispositivos_iot`
--
ALTER TABLE `dispositivos_iot`
  ADD CONSTRAINT `fk_dispositivos_ubicacion` FOREIGN KEY (`id_ubicacion`) REFERENCES `ubicaciones` (`id_ubicacion`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  ADD CONSTRAINT `fk_mov_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  ADD CONSTRAINT `fk_mov_ubicacion` FOREIGN KEY (`id_ubicacion`) REFERENCES `ubicaciones` (`id_ubicacion`),
  ADD CONSTRAINT `fk_mov_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_productos_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_productos_estatus` FOREIGN KEY (`estatus`) REFERENCES `descripcion_estatus` (`id_descripcion_estatus`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `ubicacion_productos`
--
ALTER TABLE `ubicacion_productos`
  ADD CONSTRAINT `fk_ubicacion_almacen` FOREIGN KEY (`id_ubicacion`) REFERENCES `ubicaciones` (`id_ubicacion`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ubicacion_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`id_rol`) REFERENCES `rol` (`id_rol`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
