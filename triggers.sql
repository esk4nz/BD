-- 1 Вставка каунтера
CREATE OR REPLACE FUNCTION insert_counter_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF is_counter_needed_fun(NEW.counter_type) = TRUE THEN
        INSERT INTO Debt(account_id, category_name) VALUES (NEW.account_id, NEW.counter_type);
        UPDATE Debt SET debt = (NEW.number_on_counter_now - NEW.number_on_counter_then) * 
        get_tariff(NEW.counter_type) / 1000
        WHERE account_id = NEW.account_id AND category_name = NEW.counter_type;
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;

CREATE TRIGGER insert_counter
BEFORE INSERT ON Counter
FOR EACH ROW
EXECUTE FUNCTION insert_counter_fun();

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- 2 Вставка поповнення балансу
CREATE OR REPLACE FUNCTION insert_top_up_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE PersonalCabinet SET balance = balance + NEW.top_up_sum WHERE NEW.user_id = PersonalCabinet.user_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER insert_top_up
AFTER INSERT ON PaymentTopUp
FOR EACH ROW
EXECUTE FUNCTION insert_top_up_fun();

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--3 Вставка боргу
CREATE OR REPLACE FUNCTION insert_debt_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    temp INT := 0;
    months INT;
BEGIN
    IF is_counter_needed_fun(NEW.category_name) = FALSE THEN
        SELECT user_id INTO months FROM AccountCabinetLink ac WHERE ac.account_id = NEW.account_id;
        temp := NEW.debt + (get_tariff(NEW.category_name) * get_months(months));
        UPDATE Debt
        SET debt = temp
        WHERE account_id = NEW.account_id AND category_name = NEW.category_name;
        UPDATE Debt
        SET debt = get_tariff(NEW.category_name) * 2
        WHERE debt IS NULL;
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;

CREATE TRIGGER insert_debt
AFTER INSERT ON Debt
FOR EACH ROW
EXECUTE FUNCTION insert_debt_fun();


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--4 Редагування лічильника
CREATE OR REPLACE FUNCTION update_counter_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    new_debt NUMERIC(10, 2);
    prev_number_on_counter_now INT;
BEGIN

    prev_number_on_counter_now := OLD.number_on_counter_now;

    IF NEW.number_on_counter_then <> OLD.number_on_counter_then AND NEW.number_on_counter_now = OLD.number_on_counter_now AND NEW.counter_type = OLD.counter_type THEN
        RETURN NULL;
    END IF;

    IF NEW.counter_type <> OLD.counter_type THEN
            RAISE NOTICE 'Cannot update counter type as it violates the unique constraint in Debt table.';
            RETURN NULL;
    END IF;

    IF NEW.number_on_counter_now >= OLD.number_on_counter_now THEN
        NEW.number_on_counter_then := prev_number_on_counter_now;
        new_debt := (NEW.number_on_counter_now - NEW.number_on_counter_then) * get_tariff(NEW.counter_type) / 1000;

        UPDATE Debt 
        SET debt = debt + new_debt
        WHERE account_id = NEW.account_id 
        AND category_name = NEW.counter_type;
    ELSE
        RAISE NOTICE 'New counter value must be greater than or equal to the previous value';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER update_counter
BEFORE UPDATE ON Counter
FOR EACH ROW
EXECUTE FUNCTION update_counter_fun();

DELETE FROM counter;
DELETE FROM Debt;

-- SELECT * FROM debt WHERE account_id = 39;
-- SELECT * FROM Counter WHERE account_id = 39;
-- UPDATE Counter
-- SET number_on_counter_now = 3000
-- WHERE account_id = 55 AND counter_type = 'Cold water';
-- SELECT * FROM debt WHERE account_id = 55;
-- SELECT * FROM Counter WHERE account_id = 55;

-- SELECT * FROM debt WHERE account_id = 15;
-- SELECT * FROM Counter WHERE account_id = 15;
-- UPDATE Counter
-- SET counter_type = 'Gas supply'
-- WHERE account_id = 55 AND counter_type = 'Hot water';
-- SELECT * FROM debt WHERE account_id = 55;
-- SELECT * FROM Counter WHERE account_id = 55;

-- SELECT * FROM debt WHERE account_id = 1;
-- SELECT * FROM Counter WHERE account_id = 1;
-- UPDATE Counter
-- SET counter_type = 'Heating'
-- WHERE account_id = 1 AND counter_type = 'Cold water';
-- SELECT * FROM debt WHERE account_id = 1;
-- SELECT * FROM Counter WHERE account_id = 1;

-- SELECT * FROM debt WHERE account_id = 39;
-- SELECT * FROM Counter WHERE account_id = 39;
-- UPDATE Counter
-- SET number_on_counter_then = 1333
-- WHERE account_id = 39 AND counter_type = 'Cold water';
-- SELECT * FROM debt WHERE account_id = 39;
-- SELECT * FROM Counter WHERE account_id = 39;

--5 Видалення лічильника
CREATE OR REPLACE FUNCTION delete_counter_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Debt WHERE OLD.account_id = Debt.account_id AND OLD.counter_type = Debt.category_name;
    RETURN NEW;
END;
$$;

CREATE TRIGGER delete_counter
AFTER DELETE ON Counter
FOR EACH ROW
EXECUTE FUNCTION delete_counter_fun();



------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- 6 Вставка в оплату
CREATE OR REPLACE FUNCTION insert_payment_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    user_balance NUMERIC(10, 2);
    current_debt NUMERIC(10, 2);
    debt_exists BOOLEAN;
    actual_payment_amount NUMERIC(10, 2);
BEGIN
    SELECT EXISTS(SELECT 1 FROM Debt WHERE account_id = (SELECT account_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id) AND category_name = NEW.category_name) INTO debt_exists;

    IF NOT debt_exists THEN
        RAISE EXCEPTION 'Debt for the specified account_id and category_name does not exist.';
    END IF;

    SELECT balance, debt INTO user_balance, current_debt FROM PersonalCabinet
    JOIN AccountCabinetLink ON PersonalCabinet.user_id = AccountCabinetLink.user_id
    JOIN Debt ON AccountCabinetLink.account_id = Debt.account_id
    WHERE AccountCabinetLink.account_cabinet_link_id = NEW.account_cabinet_link_id
    AND Debt.category_name = NEW.category_name;



    IF current_debt = 0 THEN
        RAISE NOTICE 'The debt for this category is 0';
        RETURN NULL;
    END IF;

    IF user_balance < NEW.payment_sum THEN
        RAISE NOTICE 'Payment exceeds the user balance.';
        RETURN NULL;
    END IF;

    IF NEW.payment_sum > current_debt THEN
        RAISE NOTICE 'Payment exceeds the current debt.';
        RETURN NULL;
    END IF;

    UPDATE PersonalCabinet
    SET balance = balance - NEW.payment_sum
    WHERE PersonalCabinet.user_id = (SELECT user_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id);

    UPDATE Debt
    SET debt = debt - NEW.payment_sum
    WHERE account_id = (SELECT account_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id)
    AND category_name = NEW.category_name;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$;

CREATE TRIGGER insert_payment
BEFORE INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION insert_payment_fun();


-- SELECT * FROM PersonalCabinet pc WHERE pc.user_id = 26;

-- SELECT d.* FROM Debt d JOIN PersonalAccount pa ON pa.account_id = d.account_id JOIN AccountCabinetLink a ON a.account_id = pa.account_id WHERE a.user_id = 26 AND a.account_id = 39;

-- SELECT * FROM Payment p JOIN AccountCabinetLink a ON p.account_cabinet_link_id = a.account_cabinet_link_id JOIN PersonalCabinet pc ON pc.user_id = a.user_id WHERE pc.user_id = 26 AND a.account_id = 39;


-- INSERT INTO Payment(date_of_payment, payment_sum, category_name, account_cabinet_link_id) VALUES('2023-12-30', 1000, 'Heating', 39);

-- SELECT * FROM PersonalCabinet WHERE user_id = 3;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- 7 Апдейт PaymentTopUp
CREATE OR REPLACE FUNCTION update_PaymentTopUp_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    payment_difference NUMERIC(10,2);
    user_balance NUMERIC(10,2);
BEGIN
    payment_difference := NEW.top_up_sum - OLD.top_up_sum;
    SELECT balance INTO user_balance FROM PersonalCabinet WHERE user_id = NEW.user_id;
    UPDATE PersonalCabinet
    SET balance = balance + payment_difference
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$;


CREATE TRIGGER update_PaymentTopUp
AFTER UPDATE ON PaymentTopUp
FOR EACH ROW
EXECUTE FUNCTION update_PaymentTopUp_fun();

-- SELECT * FROM PaymentTopUp WHERE payment_top_up_id = 1;
-- SELECT balance FROM personalcabinet where user_id = 7;
-- UPDATE PaymentTopUp SET top_up_sum = 959 WHERE payment_top_up_id = 1;
-- SELECT * FROM PaymentTopUp WHERE payment_top_up_id = 1;
-- SELECT balance FROM personalcabinet where user_id = 7;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_before_PaymentTopUp_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    payment_difference NUMERIC(10,2);
    user_balance NUMERIC(10,2);
BEGIN
    IF NEW.user_id <> OLD.user_id OR NEW.card_id <> OLD.card_id THEN    
         RAISE NOTICE 'You cannot change the card or user';
         RETURN NULL;
    END IF;
    payment_difference := NEW.top_up_sum - OLD.top_up_sum;
    SELECT balance INTO user_balance FROM PersonalCabinet WHERE user_id = NEW.user_id;
    IF NEW.top_up_sum < OLD.top_up_sum THEN
        IF user_balance < payment_difference THEN
            RAISE NOTICE 'You cannot change the sum because the balance is less then difference between new and old payment';
            RETURN NULL;
        END IF;
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred while updating the payment.';
        RETURN NULL;
END;
$$;


CREATE TRIGGER update_before_PaymentTopUp
BEFORE UPDATE ON PaymentTopUp
FOR EACH ROW
EXECUTE FUNCTION update_before_PaymentTopUp_fun();


-- SELECT * FROM PaymentTopUp WHERE payment_top_up_id = 1;
-- SELECT balance FROM personalcabinet where user_id = 7;
-- UPDATE PaymentTopUp SET user_id = 10 WHERE payment_top_up_id = 1;
-- SELECT * FROM PaymentTopUp WHERE payment_top_up_id = 1;
-- SELECT balance FROM personalcabinet where user_id = 7;



------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- 8 Апдейт Payment
CREATE OR REPLACE FUNCTION update_before_payment_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    original_payment_sum NUMERIC(10, 2);
    payment_difference NUMERIC(10, 2);
    user_balance NUMERIC(10, 2);
    current_debt NUMERIC(10, 2);
    category_exists BOOLEAN;
    debt_exists BOOLEAN;
BEGIN
    IF NEW.account_cabinet_link_id <> OLD.account_cabinet_link_id OR NEW.category_name <> OLD.category_name THEN    
         RAISE NOTICE 'You cannot change the acc or category name';
         RETURN NULL;
    END IF;

    SELECT EXISTS(SELECT 1 FROM Category WHERE category_name = NEW.category_name) INTO category_exists;
    IF NOT category_exists THEN
        RAISE NOTICE 'Payment category does not exist';
        RETURN NULL;
    END IF;

    SELECT EXISTS(SELECT 1 FROM Debt WHERE account_id = (SELECT account_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id) AND category_name = NEW.category_name) INTO debt_exists;
    IF NOT debt_exists THEN
        RAISE NOTICE 'There is no debt for the given category and account';
        RETURN NULL;
    END IF;

    payment_difference := NEW.payment_sum - OLD.payment_sum;
    SELECT balance INTO user_balance FROM PersonalCabinet
    WHERE user_id = (SELECT user_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id);

    SELECT debt, account_id INTO current_debt FROM Debt
    WHERE account_id = (SELECT account_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id)
    AND category_name = NEW.category_name;

    IF user_balance < payment_difference THEN
        RAISE NOTICE 'Insufficient balance for increased payment beb.';
        RETURN NULL;
    END IF;

    IF current_debt = 0 AND payment_difference > 0 THEN
        RAISE NOTICE 'Insufficient debt for increased payment fef.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER update_before_payment
BEFORE UPDATE ON Payment
FOR EACH ROW
EXECUTE FUNCTION update_before_payment_fun();


SELECT balance, user_id FROM personalcabinet where user_id = (SELECT user_id from accountcabinetlink WHERE account_cabinet_link_id = 45);
SELECT * FROM Debt where account_id = (SELECT account_id from accountcabinetlink WHERE account_cabinet_link_id = 45) AND category_name = 'Carrying out energy efficiency works';

SELECT * FROM payment where account_cabinet_link_id = 45;

UPDATE Payment
SET payment_sum = 4800.0
WHERE account_cabinet_link_id = 45 AND category_name = 'Carrying out energy efficiency works';


-- UPDATE Debt
-- SET debt = 10
-- where account_id = (SELECT account_id from accountcabinetlink WHERE account_cabinet_link_id = 45) AND category_name = 'Carrying out energy efficiency works';

-- UPDATE personalcabinet
-- SET balance = 2
-- where user_id = 21;
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_payment_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    payment_difference NUMERIC(10,2);
    user_balance NUMERIC(10,2);
    original_payment_sum NUMERIC(10, 2);
    current_debt NUMERIC(10, 2);
    account_id_ INT;
    new_payment NUMERIC(10, 2);
BEGIN
    payment_difference := NEW.payment_sum - OLD.payment_sum;
    SELECT balance INTO user_balance FROM PersonalCabinet
    WHERE user_id = (SELECT user_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id);

    SELECT debt, account_id INTO current_debt, account_id_ FROM Debt
    WHERE account_id = (SELECT account_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id)
    AND category_name = NEW.category_name;

    UPDATE PersonalCabinet
    SET balance = balance - payment_difference
    WHERE user_id = (SELECT user_id FROM AccountCabinetLink WHERE account_cabinet_link_id = NEW.account_cabinet_link_id);

    UPDATE Debt
    SET debt = debt - payment_difference
    WHERE account_id = account_id_ AND category_name = NEW.category_name;

    RETURN NEW;
END;
$$;


CREATE TRIGGER update_payment
AFTER UPDATE ON Payment
FOR EACH ROW
EXECUTE FUNCTION update_payment_fun();


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- 9 Апдейт Дебт
CREATE OR REPLACE FUNCTION update_before_debt_fun()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    original_payment_sum NUMERIC(10, 2);
    payment_difference NUMERIC(10, 2);
    user_balance NUMERIC(10, 2);
    current_debt NUMERIC(10, 2);
BEGIN
    IF NEW.account_id <> OLD.account_id OR NEW.category_name <> OLD.category_name THEN    
         RAISE NOTICE 'You cannot change the acc or category name';
         RETURN NULL;
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred while updating the payment.';
        RETURN NULL;
END;
$$;

CREATE TRIGGER update_before_debt
BEFORE UPDATE ON Debt
FOR EACH ROW
EXECUTE FUNCTION update_before_debt_fun();



-- SELECT * FROM Debt where account_id = 3;


-- UPDATE Debt
-- SET debt = 534.43
-- where account_id = 3 AND category_name = 'Gas supply';

