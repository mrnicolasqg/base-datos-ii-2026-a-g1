-- Archivo: nicolas_quiz.sql

-- Consulta con múltiples INNER JOIN (estructura distinta)
SELECT
    r.reservation_code AS reserva,
    f.flight_number AS vuelo,
    f.service_date AS fecha,
    t.ticket_number AS tiquete,
    rp.passenger_sequence_no AS orden_pasajero,
    (p.first_name || ' ' || p.last_name) AS nombre_completo,
    fs.segment_number AS segmento,
    fs.scheduled_departure_at AS salida
FROM reservation r
JOIN reservation_passenger rp 
    ON r.reservation_id = rp.reservation_id
JOIN person p 
    ON p.person_id = rp.person_id
JOIN ticket t 
    ON t.reservation_passenger_id = rp.reservation_passenger_id
JOIN ticket_segment ts 
    ON ts.ticket_id = t.ticket_id
JOIN flight_segment fs 
    ON fs.flight_segment_id = ts.flight_segment_id
JOIN flight f 
    ON f.flight_id = fs.flight_id
ORDER BY fecha, vuelo;

---------------------------------------------------

-- Nueva función para generar boarding pass (cambiada)
CREATE OR REPLACE FUNCTION generar_pase_abordaje()
RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO boarding_pass (
        check_in_id,
        boarding_pass_code,
        barcode_value,
        issued_at
    )
    VALUES (
        NEW.check_in_id,
        'PASS-' || NEW.check_in_id::text,
        'CODE-' || EXTRACT(EPOCH FROM NOW()),
        CURRENT_TIMESTAMP
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------

-- Trigger modificado
DROP TRIGGER IF EXISTS trigger_pase_abordaje ON check_in;

CREATE TRIGGER trigger_pase_abordaje
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION generar_pase_abordaje();

---------------------------------------------------

-- Procedimiento almacenado modificado
CREATE OR REPLACE PROCEDURE registrar_checkin_simple(
    IN ticket_seg uuid,
    IN estado uuid,
    IN grupo uuid,
    IN usuario uuid
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO check_in (
        ticket_segment_id,
        check_in_status_id,
        boarding_group_id,
        checked_in_by_user_id,
        checked_in_at
    )
    VALUES (
        ticket_seg,
        estado,
        grupo,
        usuario,
        NOW()
    );
END;
$$;

---------------------------------------------------

-- Insert de prueba (para activar trigger)
INSERT INTO check_in (
    ticket_segment_id,
    check_in_status_id,
    boarding_group_id,
    checked_in_by_user_id,
    checked_in_at
)
VALUES (
    'UUID_TEST_1',
    'UUID_TEST_2',
    'UUID_TEST_3',
    'UUID_TEST_4',
    CURRENT_TIMESTAMP
);

---------------------------------------------------

-- Validación del trigger (versión simplificada)
SELECT
    ci.check_in_id,
    ci.checked_in_at,
    bp.boarding_pass_code,
    bp.barcode_value
FROM check_in ci
JOIN boarding_pass bp 
    ON bp.check_in_id = ci.check_in_id;

---------------------------------------------------

-- Consulta final con LEFT JOIN (ligeramente diferente)
SELECT
    f.flight_number,
    r.reservation_code,
    p.first_name,
    t.ticket_number,
    ci.check_in_id,
    bp.boarding_pass_code
FROM flight f
JOIN flight_segment fs ON f.flight_id = fs.flight_id
JOIN ticket_segment ts ON fs.flight_segment_id = ts.flight_segment_id
JOIN ticket t ON ts.ticket_id = t.ticket_id
JOIN reservation_passenger rp ON t.reservation_passenger_id = rp.reservation_passenger_id
JOIN reservation r ON rp.reservation_id = r.reservation_id
JOIN person p ON p.person_id = rp.person_id
LEFT JOIN check_in ci ON ci.ticket_segment_id = ts.ticket_segment_id
LEFT JOIN boarding_pass bp ON bp.check_in_id = ci.check_in_id;
