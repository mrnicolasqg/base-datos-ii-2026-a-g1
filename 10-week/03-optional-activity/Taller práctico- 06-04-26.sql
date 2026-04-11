-- ============================================================
-- PERMISSIONS DB
-- ============================================================

CREATE ROLE admin_role;
CREATE ROLE agent_role;
CREATE ROLE readonly_role;

CREATE USER admin_user WITH PASSWORD 'Admin2026!';
CREATE USER agent_user WITH PASSWORD 'Agent2026!';
CREATE USER report_user WITH PASSWORD 'Report2026!';

GRANT admin_role TO admin_user;
GRANT agent_role TO agent_user;
GRANT readonly_role TO report_user;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;

GRANT SELECT, INSERT, UPDATE ON reservation TO agent_role;
GRANT SELECT, INSERT, UPDATE ON reservation_passenger TO agent_role;
GRANT SELECT, INSERT, UPDATE ON ticket TO agent_role;
GRANT SELECT, INSERT, UPDATE ON ticket_segment TO agent_role;
GRANT SELECT, INSERT, UPDATE ON sale TO agent_role;
GRANT SELECT, INSERT, UPDATE ON payment TO agent_role;
GRANT SELECT, INSERT, UPDATE ON check_in TO agent_role;
GRANT SELECT, INSERT, UPDATE ON boarding_pass TO agent_role;
GRANT SELECT, INSERT, UPDATE ON seat_assignment TO agent_role;
GRANT SELECT, INSERT, UPDATE ON baggage TO agent_role;
GRANT SELECT ON flight TO agent_role;
GRANT SELECT ON flight_segment TO agent_role;
GRANT SELECT ON aircraft TO agent_role;
GRANT SELECT ON aircraft_seat TO agent_role;
GRANT SELECT ON airport TO agent_role;
GRANT SELECT ON customer TO agent_role;
GRANT SELECT ON person TO agent_role;
GRANT SELECT ON fare TO agent_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;

REVOKE DELETE ON reservation FROM agent_role;
REVOKE DELETE ON ticket FROM agent_role;
REVOKE DELETE ON payment FROM agent_role;

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reservation_updated_at
    BEFORE UPDATE ON reservation
    FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE TRIGGER trg_ticket_updated_at
    BEFORE UPDATE ON ticket
    FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE TRIGGER trg_payment_updated_at
    BEFORE UPDATE ON payment
    FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE TRIGGER trg_flight_updated_at
    BEFORE UPDATE ON flight
    FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE TRIGGER trg_customer_updated_at
    BEFORE UPDATE ON customer
    FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE OR REPLACE FUNCTION fn_validate_flight_segment_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.scheduled_arrival_at <= NEW.scheduled_departure_at THEN
        RAISE EXCEPTION 'La llegada programada debe ser posterior a la salida programada.';
    END IF;
    IF NEW.actual_departure_at IS NOT NULL AND NEW.actual_arrival_at IS NOT NULL THEN
        IF NEW.actual_arrival_at <= NEW.actual_departure_at THEN
            RAISE EXCEPTION 'La llegada real debe ser posterior a la salida real.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_flight_segment_dates
    BEFORE INSERT OR UPDATE ON flight_segment
    FOR EACH ROW EXECUTE FUNCTION fn_validate_flight_segment_dates();

CREATE OR REPLACE FUNCTION fn_validate_seat_not_duplicated()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict_count integer;
BEGIN
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM seat_assignment sa
    JOIN ticket_segment ts ON sa.ticket_segment_id = ts.ticket_segment_id
    WHERE sa.aircraft_seat_id = NEW.aircraft_seat_id
      AND ts.flight_segment_id = (
          SELECT flight_segment_id FROM ticket_segment WHERE ticket_segment_id = NEW.ticket_segment_id
      )
      AND sa.seat_assignment_id <> COALESCE(NEW.seat_assignment_id, gen_random_uuid());

    IF v_conflict_count > 0 THEN
        RAISE EXCEPTION 'El asiento ya está asignado para este segmento de vuelo.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_seat_not_duplicated
    BEFORE INSERT OR UPDATE ON seat_assignment
    FOR EACH ROW EXECUTE FUNCTION fn_validate_seat_not_duplicated();

CREATE OR REPLACE FUNCTION fn_log_payment_insert()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Nuevo pago registrado: id=%, sale_id=%, monto=%, estado=%',
        NEW.payment_id, NEW.sale_id, NEW.total_amount, NEW.payment_status_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_payment_insert
    AFTER INSERT ON payment
    FOR EACH ROW EXECUTE FUNCTION fn_log_payment_insert();

-- ============================================================
-- FUNCTIONS USER
-- ============================================================

CREATE OR REPLACE FUNCTION fn_get_customer_full_name(p_customer_id uuid)
RETURNS text AS $$
DECLARE
    v_full_name text;
BEGIN
    SELECT TRIM(
        COALESCE(p.first_name, '') || ' ' ||
        COALESCE(p.middle_name || ' ', '') ||
        COALESCE(p.last_name, '') || ' ' ||
        COALESCE(p.second_last_name, '')
    )
    INTO v_full_name
    FROM customer c
    JOIN person p ON p.person_id = c.person_id
    WHERE c.customer_id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente con id % no encontrado.', p_customer_id;
    END IF;

    RETURN v_full_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_get_loyalty_miles_balance(p_loyalty_account_id uuid)
RETURNS integer AS $$
DECLARE
    v_balance integer;
BEGIN
    SELECT COALESCE(SUM(miles_delta), 0)
    INTO v_balance
    FROM miles_transaction
    WHERE loyalty_account_id = p_loyalty_account_id;

    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_customer_active_reservations(p_customer_id uuid)
RETURNS TABLE (
    reservation_id uuid,
    reservation_code varchar,
    booked_at timestamptz,
    status_code varchar
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.reservation_id, r.reservation_code, r.booked_at, rs.status_code
    FROM reservation r
    JOIN reservation_status rs ON rs.reservation_status_id = r.reservation_status_id
    WHERE r.booked_by_customer_id = p_customer_id
      AND rs.status_code NOT IN ('CANCELLED', 'COMPLETED')
    ORDER BY r.booked_at DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_get_available_seats(p_flight_segment_id uuid)
RETURNS integer AS $$
DECLARE
    v_total integer;
    v_occupied integer;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM aircraft_seat acs
    JOIN aircraft_cabin acb ON acb.aircraft_cabin_id = acs.aircraft_cabin_id
    JOIN aircraft a ON a.aircraft_id = acb.aircraft_id
    JOIN flight f ON f.aircraft_id = a.aircraft_id
    JOIN flight_segment fs ON fs.flight_id = f.flight_id
    WHERE fs.flight_segment_id = p_flight_segment_id;

    SELECT COUNT(*)
    INTO v_occupied
    FROM seat_assignment sa
    JOIN ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id
    WHERE ts.flight_segment_id = p_flight_segment_id;

    RETURN v_total - v_occupied;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTIONS SYSTEM
-- ============================================================

CREATE OR REPLACE FUNCTION fn_system_generate_boarding_number(p_flight_segment_id uuid)
RETURNS varchar AS $$
DECLARE
    v_seq integer;
    v_number varchar;
BEGIN
    SELECT COUNT(*) + 1
    INTO v_seq
    FROM boarding_pass bp
    JOIN check_in ci ON ci.check_in_id = bp.check_in_id
    JOIN ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
    WHERE ts.flight_segment_id = p_flight_segment_id;

    v_number := 'BP-' || LPAD(v_seq::text, 5, '0') || '-' ||
                UPPER(SUBSTRING(gen_random_uuid()::text, 1, 6));
    RETURN v_number;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_system_cleanup_expired_reservations()
RETURNS integer AS $$
DECLARE
    v_cancelled_count integer;
    v_expired_status_id uuid;
BEGIN
    SELECT reservation_status_id INTO v_expired_status_id
    FROM reservation_status
    WHERE status_code = 'CANCELLED'
    LIMIT 1;

    IF v_expired_status_id IS NULL THEN
        RAISE EXCEPTION 'Estado CANCELLED no encontrado en reservation_status.';
    END IF;

    UPDATE reservation
    SET reservation_status_id = v_expired_status_id,
        updated_at = now()
    WHERE expires_at < now()
      AND reservation_status_id NOT IN (
          SELECT reservation_status_id FROM reservation_status
          WHERE status_code IN ('CANCELLED', 'COMPLETED')
      );

    GET DIAGNOSTICS v_cancelled_count = ROW_COUNT;
    RETURN v_cancelled_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_system_flight_occupancy_rate(p_flight_segment_id uuid)
RETURNS numeric AS $$
DECLARE
    v_total integer;
    v_occupied integer;
BEGIN
    v_total := fn_get_available_seats(p_flight_segment_id);

    SELECT COUNT(*)
    INTO v_occupied
    FROM seat_assignment sa
    JOIN ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id
    WHERE ts.flight_segment_id = p_flight_segment_id;

    IF (v_total + v_occupied) = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND((v_occupied::numeric / (v_total + v_occupied)::numeric) * 100, 2);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_system_apply_miles(
    p_loyalty_account_id uuid,
    p_transaction_type varchar,
    p_miles integer,
    p_reference_code varchar DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    IF p_transaction_type NOT IN ('EARN', 'REDEEM', 'ADJUST') THEN
        RAISE EXCEPTION 'Tipo de transacción inválido: %', p_transaction_type;
    END IF;
    IF p_miles = 0 THEN
        RAISE EXCEPTION 'El delta de millas no puede ser cero.';
    END IF;

    INSERT INTO miles_transaction (
        loyalty_account_id, transaction_type, miles_delta,
        occurred_at, reference_code
    ) VALUES (
        p_loyalty_account_id, p_transaction_type, p_miles,
        now(), p_reference_code
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_register_customer(
    p_first_name varchar,
    p_last_name varchar,
    p_birth_date date,
    p_gender_code varchar,
    p_nationality_country_id uuid,
    p_person_type_code varchar,
    p_airline_id uuid,
    OUT p_customer_id uuid
)
LANGUAGE plpgsql AS $$
DECLARE
    v_person_id uuid;
    v_person_type_id uuid;
BEGIN
    SELECT person_type_id INTO v_person_type_id
    FROM person_type WHERE type_code = p_person_type_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tipo de persona % no encontrado.', p_person_type_code;
    END IF;

    INSERT INTO person (
        person_type_id, nationality_country_id,
        first_name, last_name, birth_date, gender_code
    ) VALUES (
        v_person_type_id, p_nationality_country_id,
        p_first_name, p_last_name, p_birth_date, p_gender_code
    ) RETURNING person_id INTO v_person_id;

    INSERT INTO customer (airline_id, person_id)
    VALUES (p_airline_id, v_person_id)
    RETURNING customer_id INTO p_customer_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_create_reservation(
    p_customer_id uuid,
    p_reservation_code varchar,
    p_expires_at timestamptz,
    OUT p_reservation_id uuid
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status_id uuid;
BEGIN
    SELECT reservation_status_id INTO v_status_id
    FROM reservation_status WHERE status_code = 'PENDING'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estado PENDING no encontrado en reservation_status.';
    END IF;

    INSERT INTO reservation (
        booked_by_customer_id, reservation_status_id,
        reservation_code, booked_at, expires_at
    ) VALUES (
        p_customer_id, v_status_id,
        p_reservation_code, now(), p_expires_at
    ) RETURNING reservation_id INTO p_reservation_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_process_check_in(
    p_ticket_segment_id uuid,
    p_aircraft_seat_id uuid,
    OUT p_boarding_pass_id uuid
)
LANGUAGE plpgsql AS $$
DECLARE
    v_check_in_status_id uuid;
    v_check_in_id uuid;
    v_boarding_number varchar;
    v_flight_segment_id uuid;
BEGIN
    SELECT flight_segment_id INTO v_flight_segment_id
    FROM ticket_segment WHERE ticket_segment_id = p_ticket_segment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ticket_segment % no encontrado.', p_ticket_segment_id;
    END IF;

    SELECT check_in_status_id INTO v_check_in_status_id
    FROM check_in_status WHERE status_code = 'COMPLETED'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estado COMPLETED no encontrado en check_in_status.';
    END IF;

    INSERT INTO check_in (ticket_segment_id, check_in_status_id, checked_in_at)
    VALUES (p_ticket_segment_id, v_check_in_status_id, now())
    RETURNING check_in_id INTO v_check_in_id;

    INSERT INTO seat_assignment (ticket_segment_id, aircraft_seat_id, assigned_at)
    VALUES (p_ticket_segment_id, p_aircraft_seat_id, now());

    v_boarding_number := fn_system_generate_boarding_number(v_flight_segment_id);

    INSERT INTO boarding_pass (check_in_id, boarding_number, issued_at)
    VALUES (v_check_in_id, v_boarding_number, now())
    RETURNING boarding_pass_id INTO p_boarding_pass_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_register_payment(
    p_sale_id uuid,
    p_payment_method_id uuid,
    p_currency_id uuid,
    p_total_amount numeric,
    p_transaction_reference varchar,
    OUT p_payment_id uuid
)
LANGUAGE plpgsql AS $$
DECLARE
    v_payment_status_id uuid;
BEGIN
    SELECT payment_status_id INTO v_payment_status_id
    FROM payment_status WHERE status_code = 'COMPLETED'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estado COMPLETED no encontrado en payment_status.';
    END IF;

    INSERT INTO payment (
        sale_id, payment_method_id, payment_status_id,
        currency_id, total_amount, paid_at
    ) VALUES (
        p_sale_id, p_payment_method_id, v_payment_status_id,
        p_currency_id, p_total_amount, now()
    ) RETURNING payment_id INTO p_payment_id;

    INSERT INTO payment_transaction (
        payment_id, transaction_reference, transaction_amount, transacted_at
    ) VALUES (
        p_payment_id, p_transaction_reference, p_total_amount, now()
    );
END;
$$;
