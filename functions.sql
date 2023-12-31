-- 1 дістати тариф
CREATE OR REPLACE FUNCTION get_tariff(category VARCHAR(70))
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql AS $$
DECLARE
    tariff NUMERIC(10,2) := 0;
BEGIN
    IF EXISTS (SELECT 1 FROM Category ca WHERE ca.category_name = category) THEN
        SELECT sr.cost_per_unit_of_service INTO tariff
        FROM ServiceRate sr, Category ca 
        WHERE sr.service_rate_id = ca.service_rate_id 
        AND ca.category_name = category;
        RETURN tariff;
    ELSE
        RAISE NOTICE 'The category (%) does not exist', category;
        RETURN NULL;
    END IF;
END;
$$;

-- SELECT * FROM get_tariff('Cold water');


-- 2 дістати кількість місяців, яка пройшла з моменту найпершого поповенення
CREATE OR REPLACE FUNCTION get_months(id INT)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    months INT := 0;
BEGIN
    IF EXISTS (SELECT 1 FROM PaymentTopUp pt WHERE pt.user_id = id) THEN
        SELECT EXTRACT(YEAR FROM age(current_date, date_of_top_up-1)) * 12 + EXTRACT(MONTH FROM age(current_date, date_of_top_up-1)) AS months_passed
        INTO months FROM PaymentTopUp WHERE payment_top_up_id = 1;
        RETURN months;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;

-- SELECT * FROM get_months(7);


-- 3 Середній борг усіх користувачів по певній категорії
CREATE OR REPLACE FUNCTION avg_debt(name_of_category VARCHAR(70))
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql AS $$
DECLARE
    average NUMERIC(10,2);
BEGIN
    SELECT AVG(debt) INTO average FROM Debt WHERE category_name = name_of_category;
    RETURN average;
END;
$$;

-- SELECT avg_debt('Cold water');

-- 4 Усі борги, які має користувач
CREATE OR REPLACE FUNCTION all_debts(id INT)
RETURNS TABLE(category_name VARCHAR(70), debt_count DECIMAL(10,2))
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM PersonalCabinet WHERE user_id = id) THEN
        RETURN QUERY
        SELECT d.category_name, SUM(debt) FROM Debt d JOIN PersonalAccount pa ON pa.account_id = d.account_id 
        JOIN AccountCabinetLink a ON pa.account_id = a.account_id WHERE a.user_id = id GROUP BY (d.category_name);
    ELSE
        RAISE NOTICE 'The user with % id does not exist', id;
    END IF;
END;
$$;

-- SELECT * FROM all_debts(4);

-- 5 Чи потребує певна категорія каунтер
CREATE OR REPLACE FUNCTION is_counter_needed_fun(name_of_category VARCHAR(70))
RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
    f BOOLEAN;
BEGIN
    SELECT ca.is_counter_needed INTO f FROM Category ca WHERE ca.category_name = name_of_category;
    RETURN f;
END;
$$;

-- SELECT * FROM is_counter_needed_fun('Household waste management');


-- 6 Додання нової категорії.
CREATE OR REPLACE PROCEDURE add_new_service_category(name_of_category VARCHAR(70), counter_needed BOOLEAN, cost DECIMAL(10,2))
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO ServiceRate(cost_per_unit_of_service) VALUES(cost);
    INSERT INTO Category(category_name, is_counter_needed, service_rate_id) VALUES (name_of_category, counter_needed, (SELECT MAX(service_rate_id) FROM ServiceRate));
END;
$$;

-- CALL add_new_service_category('New category', FALSE, 130);


-- 7 Оновлення електронної пошти для користувача
CREATE OR REPLACE PROCEDURE update_user_email(id INT, new_email VARCHAR(100))
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM PersonalCabinet WHERE user_id = id) AND NOT EXISTS (SELECT 1 FROM PersonalCabinet WHERE email = new_email) THEN
        UPDATE PersonalCabinet SET email = new_email WHERE user_id = id;
    ELSE
        RAISE NOTICE 'The user with % id does not exist or the email already exists', id;
    END IF;
END;
$$;

-- CALL update_user_email(1, 'new.email@gmail.com');

-- 8 Оновлення тарифу за послугу
CREATE OR REPLACE PROCEDURE update_service_rate(name_of_category VARCHAR(70), new_rate NUMERIC(10,2))
LANGUAGE plpgsql AS $$
DECLARE 
    rate_id INT;
BEGIN
    IF EXISTS (SELECT service_rate_id FROM Category WHERE category_name = name_of_category) THEN
        SELECT service_rate_id INTO rate_id FROM Category WHERE category_name = name_of_category;
        IF (SELECT cost_per_unit_of_service FROM ServiceRate WHERE service_rate_id = rate_id) <> new_rate THEN
            UPDATE ServiceRate SET cost_per_unit_of_service = new_rate WHERE service_rate_id = rate_id;
        ELSE
            RAISE NOTICE 'The new rate is the same as old one';
        END IF;
    ELSE
        RAISE NOTICE 'The category % does not exist', name_of_category;
    END IF;
END;
$$;

-- CALL update_service_rate('Hot water', 84);



-- 9 Перевірка чи не має приватний рахунок більше ніж однієї адреси
CREATE OR REPLACE PROCEDURE is_acc_unique()
LANGUAGE plpgsql AS $$
DECLARE 
    min_id INT;
    max_id INT;
    num BIGINT;
    add_id INT;
    i INT;
BEGIN
    SELECT MIN(account_id) INTO min_id FROM PersonalAccount;
    SELECT MAX(account_id) INTO max_id FROM PersonalAccount;
    i := min_id;
    while i <= max_id LOOP
        SELECT account_number, address_id INTO num, add_id FROM PersonalAccount WHERE account_id = i;
        IF EXISTS (SELECT 1 FROM PersonalAccount WHERE add_id <> address_id AND account_number = num) THEN
            RAISE NOTICE 'The number % is not unique', num;
            RETURN;
        END IF;
        i := i + 1;
    END LOOP;
    RAISE NOTICE 'All numbers are unique';
END;
$$;

CALL is_acc_unique();


-- 10 Видалення користувачів з тотальним боргом більше 8000
CREATE OR REPLACE PROCEDURE delete_users_with_high_debt()
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM PersonalCabinet
    WHERE user_id IN (
        SELECT pc.user_id
        FROM PersonalCabinet pc
        JOIN AccountCabinetLink acl ON pc.user_id = acl.user_id
        JOIN Debt d ON acl.account_id = d.account_id
        GROUP BY pc.user_id
        HAVING SUM(d.debt) > 8000
    );
END;
$$;

-- CALL delete_users_with_high_debt();

