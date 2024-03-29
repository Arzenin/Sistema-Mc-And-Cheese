-- Borrar tablas
DROP TABLE IF EXISTS TRABAJADOR;
DROP TABLE IF EXISTS PEDIDO;
DROP TABLE IF EXISTS RESERVAS;
DROP TABLE IF EXISTS CLIENTES;
DROP TABLE IF EXISTS ALERGENOS;
DROP TABLE IF EXISTS INGREDIENTES;
DROP TABLE IF EXISTS RECETAS;
DROP TABLE IF EXISTS RESERVAS_PEDIDO;
DROP TABLE IF EXISTS TRABAJADOR_PEDIDO;
DROP TABLE IF EXISTS CLIENTES_PEDIDO;
DROP TABLE IF EXISTS PEDIDO_RECETAS;
DROP TABLE IF EXISTS CLIENTES_ALERGENOS;
DROP TABLE IF EXISTS RECETAS_INGREDIENTES;
DROP TABLE IF EXISTS INGREDIENTES_ALERGENOS;
DROP TRIGGER IF EXISTS RestarPuntos;
DROP TRIGGER IF EXISTS RellenarStock;
DROP TRIGGER IF EXISTS ContieneAlergeno;

-- Activar verificación de claves foráneas
SET foreign_key_checks = 1;

-- Crear tablas


CREATE TABLE IF NOT EXISTS TRABAJADOR (
    IdTrabajador VARCHAR(20),
    Libre tinyint(1) NOT NULL,
    Turno INT,
    Bono INT CHECK(Bono <= 500),
    PRIMARY KEY(IdTrabajador)
);

CREATE TABLE IF NOT EXISTS PEDIDO (
    IdPedido INT,
    Valoracion INT CHECK(Valoracion <= 10),
    TPago VARCHAR(10) CHECK (TPago IN ('Tarjeta','Efectivo','Puntos')),
    Estado VARCHAR(10) CHECK (Estado IN ('Activo','Inactivo')),
    PRIMARY KEY(IdPedido)
);

CREATE TABLE IF NOT EXISTS RESERVAS (
    NumMesa INT UNIQUE,
    IdReserva INT,
    PRIMARY KEY(IdReserva)
);

CREATE TABLE IF NOT EXISTS CLIENTES (
    IdCliente VARCHAR(40),
    Nombre VARCHAR(40),
    UserName VARCHAR(40),
    Contrasenia VARCHAR(40),
    Domicilio VARCHAR(40),
    Puntos INT,
    FechaNacimiento VARCHAR(40),
    DatosDePago VARCHAR(30),
    PRIMARY KEY(IdCliente)
);

CREATE TABLE IF NOT EXISTS ALERGENOS (
    IdAlergeno INT,
    Nombre VARCHAR(40),
    Descripcion VARCHAR(40),
    PRIMARY KEY(IdAlergeno)
);

CREATE TABLE IF NOT EXISTS INGREDIENTES (
    IdIngrediente INT,
    Nombre VARCHAR(40),
    NumStock INT CHECK (NumStock >= 0),
    PRIMARY KEY(IdIngrediente)
);

CREATE TABLE IF NOT EXISTS RECETAS (
    IdReceta INT,
    Nombre VARCHAR(40),
    Precio INT CHECK (Precio >= 1),
    PRIMARY KEY(IdReceta)
);

CREATE TABLE IF NOT EXISTS RESERVAS_PEDIDO (
    IdReserva INT,
    IdPedido INT UNIQUE,
    NumPersonas INT,
    HoraIni VARCHAR(40),
    PRIMARY KEY(IdReserva,Horaini),
    FOREIGN KEY(IdReserva) REFERENCES RESERVAS(IdReserva),
    FOREIGN KEY(IdPedido) REFERENCES PEDIDO(IdPedido)
);

CREATE TABLE IF NOT EXISTS TRABAJADOR_PEDIDO (
    IdTrabajador VARCHAR(20),
    IdPedido INT,
    PRIMARY KEY(IdTrabajador,IdPedido),
    FOREIGN KEY(IdPedido) REFERENCES PEDIDO(IdPedido),
    FOREIGN KEY(IdTrabajador) REFERENCES TRABAJADOR(IdTrabajador)
);

CREATE TABLE IF NOT EXISTS CLIENTES_PEDIDO (
    IdCliente VARCHAR(40),
    IdPedido INT,
    PRIMARY KEY(IdPedido,IdCliente),
    FOREIGN KEY(IdPedido) REFERENCES PEDIDO(IdPedido),
    FOREIGN KEY(IdCliente) REFERENCES CLIENTES(IdCliente)
);

CREATE TABLE IF NOT EXISTS PEDIDO_RECETAS (
    IdReceta INT,
    IdPedido INT,
    numero INT CHECK (numero >= 1),
    PRIMARY KEY(IdPedido,IdReceta),
    FOREIGN KEY(IdPedido) REFERENCES PEDIDO(IdPedido),
    FOREIGN KEY(IdReceta) REFERENCES RECETAS(IdReceta)
);

CREATE TABLE IF NOT EXISTS CLIENTES_ALERGENOS (
    IdCliente VARCHAR(40),
    IdAlergeno INT,
    PRIMARY KEY(IdCliente,IdAlergeno),
    FOREIGN KEY(IdCliente) REFERENCES CLIENTES(IdCliente),
    FOREIGN KEY(IdAlergeno) REFERENCES ALERGENOS(IdAlergeno)
);

CREATE TABLE IF NOT EXISTS RECETAS_INGREDIENTES (
    IdReceta INT,
    IdIngrediente INT,
    numero INT CHECK (numero >= 1),
    PRIMARY KEY(IdReceta,IdIngrediente),
    FOREIGN KEY(IdReceta) REFERENCES RECETAS(IdReceta),
    FOREIGN KEY(IdIngrediente) REFERENCES INGREDIENTES(IdIngrediente)
);

CREATE TABLE IF NOT EXISTS INGREDIENTES_ALERGENOS (
    IdIngrediente INT,
    IdAlergeno INT,
    PRIMARY KEY(IdAlergeno,IdIngrediente),
    FOREIGN KEY(IdAlergeno) REFERENCES ALERGENOS(IdAlergeno),
    FOREIGN KEY(IdIngrediente) REFERENCES INGREDIENTES(IdIngrediente)
);

-- Crear triggers




DELIMITER //

CREATE TRIGGER ActualizarStock AFTER INSERT ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    DECLARE veces INT;
    SELECT numero INTO veces FROM PEDIDO_RECETAS WHERE IdReceta = NEW.IdReceta AND IdPedido = NEW.IdPedido;
    
    UPDATE INGREDIENTES
    JOIN RECETAS_INGREDIENTES ON INGREDIENTES.IdIngrediente = RECETAS_INGREDIENTES.IdIngrediente
    SET INGREDIENTES.NumStock = CASE
        WHEN (INGREDIENTES.NumStock - veces * RECETAS_INGREDIENTES.numero) < 0 THEN -1
        WHEN (INGREDIENTES.NumStock - veces * RECETAS_INGREDIENTES.numero) < 10 THEN 200 + INGREDIENTES.NumStock - veces * RECETAS_INGREDIENTES.numero
        ELSE (INGREDIENTES.NumStock - veces * RECETAS_INGREDIENTES.numero)
    END
    WHERE RECETAS_INGREDIENTES.IdReceta = NEW.IdReceta;
END;
//

CREATE TRIGGER ComprobarStockNoNegativo BEFORE UPDATE ON INGREDIENTES
FOR EACH ROW
BEGIN
    IF NEW.NumStock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO DEBE DE HABER STOCK NEGATIVO';
    END IF;
END;
//


CREATE TRIGGER ComprobarStockNoNegativoInit BEFORE INSERT ON INGREDIENTES
FOR EACH ROW
BEGIN
    IF NEW.NumStock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER STOCK NEGATIVO';
    END IF;
END;
//

CREATE TRIGGER RestarPuntos AFTER INSERT ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    DECLARE resta INT;
    DECLARE multiplicador INT;
    DECLARE Tipo VARCHAR(40);
    
    SELECT Precio INTO resta FROM RECETAS WHERE RECETAS.IdReceta = NEW.IdReceta;
    SELECT numero INTO multiplicador FROM PEDIDO_RECETAS WHERE PEDIDO_RECETAS.IdPedido = NEW.IdPedido AND PEDIDO_RECETAS.IdReceta = NEW.IdReceta;
    
    SET resta = resta * multiplicador;
    
    SELECT TPago INTO Tipo FROM PEDIDO WHERE PEDIDO.IdPedido = NEW.IdPedido;
    
    IF Tipo = 'Puntos' THEN
        UPDATE CLIENTES
        JOIN CLIENTES_PEDIDO ON CLIENTES_PEDIDO.IdPedido = NEW.IdPedido AND CLIENTES.IdCliente = CLIENTES_PEDIDO.IdCliente
        SET CLIENTES.Puntos = CASE
            WHEN (CLIENTES.Puntos - resta) < 0 THEN -1
            ELSE (CLIENTES.Puntos - resta)
        END
        WHERE CLIENTES_PEDIDO.IdPedido = NEW.IdPedido;
    END IF;
END;
//

CREATE TRIGGER ComprobarPuntosNoNegativo BEFORE UPDATE ON CLIENTES
FOR EACH ROW
BEGIN
    IF NEW.Puntos < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO HAY SUFICIENTES PUNTOS PARA PAGAR EL PEDIDO';
    END IF;
END;
//

CREATE TRIGGER ComprobarPuntosNoNegativoInit BEFORE INSERT ON CLIENTES
FOR EACH ROW
BEGIN
    IF NEW.Puntos < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER PUNTOS NEGATIVOS';
    END IF;
END;
//

CREATE TRIGGER ContieneAlergeno BEFORE INSERT ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    DECLARE Peligro BOOLEAN;
    SELECT 1 INTO Peligro FROM ALERGENOS
    JOIN INGREDIENTES_ALERGENOS ON ALERGENOS.IdAlergeno = INGREDIENTES_ALERGENOS.IdAlergeno
    JOIN INGREDIENTES ON INGREDIENTES_ALERGENOS.IdIngrediente = INGREDIENTES.IdIngrediente
    JOIN RECETAS_INGREDIENTES ON INGREDIENTES.IdIngrediente = RECETAS_INGREDIENTES.IdIngrediente
    WHERE RECETAS_INGREDIENTES.IdReceta = NEW.IdReceta
    AND EXISTS (
        SELECT 1
        FROM CLIENTES_ALERGENOS
        WHERE CLIENTES_ALERGENOS.IdCliente = (SELECT IdCliente FROM PEDIDO WHERE IdPedido = NEW.IdPedido)
        AND CLIENTES_ALERGENOS.IdAlergeno = ALERGENOS.IdAlergeno
    );
    
    IF Peligro THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EL CLIENTE TIENE ALERGIAS EN LA RECETA DEL PEDIDO';
    END IF;
END;
//

CREATE TRIGGER SumarPuntos AFTER INSERT ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    DECLARE suma INT;
    DECLARE multiplicador INT;
    DECLARE Tipo VARCHAR(40);
    
    SELECT Precio INTO suma FROM RECETAS WHERE RECETAS.IdReceta = NEW.IdReceta;
    SELECT numero INTO multiplicador FROM PEDIDO_RECETAS WHERE PEDIDO_RECETAS.IdPedido = NEW.IdPedido AND PEDIDO_RECETAS.IdReceta = NEW.IdReceta;
    
    SET suma = suma * multiplicador;
    
    SELECT TPago INTO Tipo FROM PEDIDO WHERE PEDIDO.IdPedido = NEW.IdPedido;
    
    IF Tipo != 'Puntos' THEN
        UPDATE CLIENTES
        JOIN CLIENTES_PEDIDO ON CLIENTES_PEDIDO.IdPedido = NEW.IdPedido AND CLIENTES.IdCliente = CLIENTES_PEDIDO.IdCliente
        SET CLIENTES.Puntos = CLIENTES.Puntos + suma
        WHERE CLIENTES_PEDIDO.IdPedido = NEW.IdPedido;
    END IF;
END;
//

CREATE TRIGGER ReservasInferior BEFORE UPDATE ON RESERVAS_PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.NumPersonas >= OLD.NumPersonas THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO SE PUEDEN AUMENTAR LAS RESERVAS A UN NUMERO MAYOR DE PERSONAS';
    END IF;
END;
//

CREATE TRIGGER CalcularBono AFTER UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.Estado = 'Inactivo' THEN
        UPDATE TRABAJADOR
        JOIN TRABAJADOR_PEDIDO ON TRABAJADOR_PEDIDO.IdTrabajador = TRABAJADOR.IdTrabajador
        JOIN PEDIDO ON TRABAJADOR_PEDIDO.IdPedido = PEDIDO.IdPedido
        SET TRABAJADOR.Bono = TRABAJADOR.Bono + PEDIDO.Valoracion
        WHERE PEDIDO.IdPedido = NEW.IdPedido;
    END IF;
END;
//

CREATE TRIGGER BonoMenor500 BEFORE UPDATE ON TRABAJADOR
FOR EACH ROW
BEGIN
    SET NEW.Bono = CASE
        WHEN NEW.Bono > 500 THEN 500
        WHEN NEW.Bono < 0 THEN 0
        ELSE NEW.Bono
    END;
END;
//

CREATE TRIGGER BonoMenor500Init BEFORE INSERT ON TRABAJADOR
FOR EACH ROW
BEGIN
    SET NEW.Bono = CASE
        WHEN NEW.Bono > 500 THEN 500
        WHEN NEW.Bono < 0 THEN 0
        ELSE NEW.Bono
    END;
END;
//

CREATE TRIGGER ValoracionMenor10 BEFORE UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    SET NEW.Valoracion = CASE
        WHEN NEW.Valoracion > 10 THEN 10
        WHEN NEW.Valoracion < 0 THEN 0
        ELSE NEW.Valoracion
    END;
END;
//

CREATE TRIGGER ValoracionMenor10Init BEFORE INSERT ON PEDIDO
FOR EACH ROW
BEGIN
    SET NEW.Valoracion = CASE
        WHEN NEW.Valoracion > 10 THEN 10
        WHEN NEW.Valoracion < 0 THEN 0
        ELSE NEW.Valoracion
    END;
END;
//

CREATE TRIGGER PrecioPositivoInit BEFORE INSERT ON RECETAS
FOR EACH ROW
BEGIN
    IF NEW.Precio < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN PRECIO NEGATIVO';
    END IF;
END;
//

CREATE TRIGGER PrecioPositivo BEFORE UPDATE ON RECETAS
FOR EACH ROW
BEGIN
    IF NEW.Precio < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN PRECIO NEGATIVO';
    END IF;
END;
//

CREATE TRIGGER EstadoEnRangoInit BEFORE INSERT ON PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.Estado != 'Activo' AND  NEW.Estado != 'Inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FUERA DEL RANGO VALIDO';
    END IF;
END;
//

CREATE TRIGGER EstadoEnRango BEFORE UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.Estado != 'Activo' AND  NEW.Estado != 'Inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FUERA DEL RANGO VALIDO';
    END IF;
END;
//

CREATE TRIGGER TipoDePagoEnRangoInit BEFORE INSERT ON PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.TPago != ('Tarjeta' AND 'Efectivo' AND 'Puntos') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TIPO DE PAGO INVALIDO';
    END IF;
END;
//

CREATE TRIGGER TipoDePagoEnRango BEFORE UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.TPago != ('Tarjeta' AND 'Efectivo' AND 'Puntos') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TIPO DE PAGO INVALIDO';
    END IF;
END;
//

CREATE TRIGGER NumRecetasPositivoInit BEFORE INSERT ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    IF NEW.numero < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE PLATOS NEGATIVOS O 0 EN EL PEDIDO';
    END IF;
END;
//


CREATE TRIGGER NumRecetasPositivo BEFORE UPDATE ON PEDIDO_RECETAS
FOR EACH ROW
BEGIN
    IF NEW.numero < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE PLATOS NEGATIVOS O 0 EN EL PEDIDO';
    END IF;
END;
//


CREATE TRIGGER NumIngredientesPositivoInit BEFORE INSERT ON RECETAS_INGREDIENTES
FOR EACH ROW
BEGIN
    IF NEW.numero < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE INGREDIENTES NEGATIVO O 0 EN LA RECETA';
    END IF;
END;
//

CREATE TRIGGER NumIngredientesPositivo BEFORE UPDATE ON RECETAS_INGREDIENTES
FOR EACH ROW
BEGIN
    IF NEW.numero < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE INGREDIENTES NEGATIVO O 0 EN LA RECETA';
    END IF;
END;
//

CREATE TRIGGER NumNumPersonasPositivoInit BEFORE INSERT ON RESERVAS_PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.NumPersonas < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE DE PERSONAS NEGATIVO O 0 EN LA MESA';
    END IF;
END;
//

CREATE TRIGGER NumNumPersonasPositivo BEFORE UPDATE ON RESERVAS_PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.NumPersonas < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NO PUEDE HABER UN NUMERO DE DE PERSONAS NEGATIVO O 0 EN LA MESA';
    END IF;
END;
//

DELIMITER ;


INSERT INTO CLIENTES (`IdCliente`, `Nombre`, `UserName`, `Contrasenia`, `Domicilio`, `Puntos`, `FechaNacimiento`, `DatosDePago`) VALUES ('gonzalo@miemail.com', 'Gonzalo Sanz Guerrero', 'gonzasanz_', '1234abc', 'Calle A', 0, '2012-12-12 00:00:00', '123A');
INSERT INTO CLIENTES (`IdCliente`, `Nombre`, `UserName`, `Contrasenia`, `Domicilio`, `Puntos`, `FechaNacimiento`, `DatosDePago`) VALUES ('jose','José Manuel Aranda Gutierrez', 'josemanuelaranda_', '12346ma', 'Calle B', 0, '2012-12-12 00:00:00', '123B');