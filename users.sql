CREATE ROLE manager;
CREATE ROLE accountant;
CREATE ROLE counter_master;



-- Надання привілеїв для ролі manager
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE PersonalCabinet TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Address TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE PersonalAccount TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Category TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ServiceRate TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE AccountCabinetLink TO manager;
GRANT SELECT ON TABLE Card TO manager;
GRANT SELECT ON TABLE Debt to manager;
GRANT SELECT ON TABLE Counter TO manager;
GRANT SELECT ON TABLE PaymentTopUp to manager;
GRANT USAGE, SELECT ON SEQUENCE personalcabinet_user_id_seq, address_address_id_seq, personalaccount_account_id_seq,
servicerate_service_rate_id_seq, accountcabinetlink_account_cabinet_link_id_seq, card_card_id_seq TO manager;

-- Надання привілеїв для ролі accountant
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Payment TO accountant;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Debt TO accountant;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE PaymentTopUp TO accountant;
GRANT SELECT, UPDATE ON TABLE PersonalCabinet TO accountant;
GRANT SELECT ON TABLE Category TO accountant;
GRANT SELECT ON TABLE ServiceRate TO accountant;
GRANT SELECT ON TABLE PersonalAccount TO accountant;
GRANT SELECT ON TABLE AccountCabinetLink TO accountant;
GRANT SELECT ON TABLE Counter TO accountant;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Card TO accountant;
GRANT USAGE, SELECT ON SEQUENCE paymenttopup_payment_top_up_id_seq, debt_debt_id_seq, payment_payment_id_seq, card_card_id_seq TO accountant;

-- Надання привілеїв для ролі counter_master
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Counter TO counter_master;
GRANT SELECT ON TABLE PersonalCabinet TO counter_master;
GRANT SELECT ON TABLE PersonalAccount TO counter_master;
GRANT SELECT ON TABLE AccountCabinetLink TO counter_master;
GRANT SELECT, INSERT, UPDATE ON TABLE Debt TO counter_master;
GRANT SELECT ON TABLE Category TO counter_master;
GRANT SELECT ON TABLE ServiceRate TO counter_master;
GRANT USAGE, SELECT ON SEQUENCE counter_counter_id_seq, debt_debt_id_seq TO counter_master;
-- Створення користувачів
CREATE USER manager_user WITH PASSWORD '1111';
CREATE USER accountant_user WITH PASSWORD '2222';
CREATE USER counter_master_user WITH PASSWORD '3333';

GRANT manager TO manager_user;
GRANT accountant TO accountant_user;
GRANT counter_master TO counter_master_user;