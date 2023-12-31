-- Представлення середнього боргу користувачів по кожній категорії
CREATE OR REPLACE VIEW AverageDebtPerCategory AS
SELECT d.category_name, AVG(d.debt) AS average_debt
FROM Debt d
GROUP BY d.category_name;
SELECT * FROM AverageDebtPerCategory;
DROP VIEW AverageDebtPerCategory;



-- Представлення кількості різних типів лічильників на кожну адресу
CREATE OR REPLACE VIEW CounterTypesPerAddress AS
SELECT ad.city, ad.street, ad.house, ad.apartment, COUNT(c.counter_type) AS counter_types_count
FROM Counter c
JOIN PersonalAccount pa ON c.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
GROUP BY ad.city, ad.street, ad.house, ad.apartment
ORDER by ad.city, ad.street, ad.house, ad.apartment;
SELECT * FROM CounterTypesPerAddress;
DROP VIEW CounterTypesPerAddress;



-- Представлення кількості платежів та загальної суми по кожному користувачу
CREATE OR REPLACE VIEW PaymentSummaryPerUser AS
SELECT pc.user_id, pc.first_name, pc.last_name, COUNT(p.payment_id) AS number_of_payments, SUM(p.payment_sum) AS total_amount_paid
FROM Payment p
JOIN AccountCabinetLink acl ON p.account_cabinet_link_id = acl.account_cabinet_link_id
JOIN PersonalCabinet pc ON acl.user_id = pc.user_id
GROUP BY pc.user_id, pc.first_name, pc.last_name
ORDER BY pc.user_id;
SELECT * FROM PaymentSummaryPerUser;
DROP VIEW PaymentSummaryPerUser;