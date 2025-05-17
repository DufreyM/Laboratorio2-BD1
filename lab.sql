
--Esta función es para la edad de quienes donan
CREATE OR REPLACE FUNCTION obtener_edad(id INT)
RETURNS INT AS $$
DECLARE
    edad INT;
BEGIN
    SELECT DATE_PART('year', AGE(fecha_nacimiento)) INTO edad
    FROM Donantes
    WHERE id_donante = id;
    RETURN edad;
END;
$$ LANGUAGE plpgsql;

--Esta es para las donaciones por el tipo de sangre
CREATE OR REPLACE FUNCTION donaciones_por_tipo(tipo TEXT)
RETURNS TABLE(nombre TEXT, apellido TEXT, fecha DATE, cantidad INT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.nombre, d.apellido, dn.fecha_donacion, dn.cantidad_ml
    FROM Donantes d
    JOIN Donaciones dn ON d.id_donante = dn.id_donante
    WHERE d.tipo_sangre = tipo;
END;
$$ LANGUAGE plpgsql;

--Esto es para simular la revisión médica.
CREATE OR REPLACE FUNCTION es_apto_para_donar(peso DECIMAL, hemoglobina DECIMAL, presion TEXT)
RETURNS TEXT AS $$
BEGIN
    IF peso >= 50 AND hemoglobina >= 12.5 AND presion = 'Normal' THEN
        RETURN 'Apto';
    ELSE
        RETURN 'No Apto';
    END IF;
END;
$$ LANGUAGE plpgsql;

--Interacción completa de insertar nueva donación y evaluación
CREATE OR REPLACE PROCEDURE insertar_donacion_evaluacion(
    p_id_donante INT, p_id_campaña INT, p_fecha DATE, p_cantidad INT,
    p_estado TEXT, p_id_personal INT, p_resultado TEXT, p_observaciones TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    new_id_donacion INT;
BEGIN
    INSERT INTO Donaciones(id_donante, id_campaña, fecha_donacion, cantidad_ml, estado)
    VALUES (p_id_donante, p_id_campaña, p_fecha, p_cantidad, p_estado)
    RETURNING id_donacion INTO new_id_donacion;

    INSERT INTO Evaluaciones(id_donacion, id_personal, resultado, observaciones)
    VALUES (new_id_donacion, p_id_personal, p_resultado, p_observaciones);
END;
$$;

--Cancelar cita que no han sido atendidad. 
CREATE OR REPLACE PROCEDURE cancelar_cita(p_id_cita INT)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Citas WHERE id_cita = p_id_cita AND estado = 'Confirmada'
    ) THEN
        UPDATE Citas SET estado = 'Cancelada' WHERE id_cita = p_id_cita;
    ELSE
        RAISE EXCEPTION 'Solo se pueden cancelar citas confirmadas.';
    END IF;
END;
$$;

--Vistas 
--Donantes con su tipo de sangre
CREATE OR REPLACE VIEW vista_donantes AS
SELECT id_donante, nombre, apellido, tipo_sangre FROM Donantes;

--Para ver la cantidad que se dono en una campaña
CREATE OR REPLACE VIEW vista_donacion_por_campaña AS
SELECT c.nombre AS campaña, SUM(d.cantidad_ml) AS total_donado
FROM Donaciones d
JOIN Campañas c ON d.id_campaña = c.id_campaña
GROUP BY c.nombre;

--Case, COALESCE 
CREATE OR REPLACE VIEW vista_estado_donaciones AS
SELECT
    d.id_donacion,
    don.nombre || ' ' || don.apellido AS donante,
    d.estado,
    CASE d.estado
        WHEN 'Aprobada' THEN '✅'
        WHEN 'Rechazada' THEN '❌'
        ELSE '⏳'
    END AS icono_estado,
    COALESCE(e.resultado, 'Sin Evaluar') AS resultado_evaluacion
FROM Donaciones d
JOIN Donantes don ON d.id_donante = don.id_donante
LEFT JOIN Evaluaciones e ON d.id_donacion = e.id_donacion;

--TRIGGERS BEFORES
CREATE OR REPLACE FUNCTION verificar_fecha_cita()
RETURNS TRIGGER AS $$
DECLARE
    fecha_inicio DATE;
    fecha_fin DATE;
BEGIN
    SELECT fecha_inicio, fecha_fin INTO fecha_inicio, fecha_fin
    FROM Campañas WHERE id_campaña = NEW.id_campaña;

    IF NEW.fecha_hora::DATE NOT BETWEEN fecha_inicio AND fecha_fin THEN
        RAISE EXCEPTION 'La cita debe estar dentro del rango de la campaña.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_fecha_cita
BEFORE INSERT ON Citas
FOR EACH ROW
EXECUTE FUNCTION verificar_fecha_cita();

--TRIGGERS AFTER
CREATE OR REPLACE FUNCTION crear_evaluacion_auto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'Aprobada' THEN
        PERFORM insertar_donacion_evaluacion(
            NEW.id_donante, NEW.id_campaña, NEW.fecha_donacion, NEW.cantidad_ml,
            NEW.estado, 1, 'Exitosa', 'Evaluación automática desde trigger'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evaluacion_donacion
AFTER INSERT ON Donaciones
FOR EACH ROW
EXECUTE FUNCTION crear_evaluacion_auto();
