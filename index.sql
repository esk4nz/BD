CREATE INDEX idx_id_cabinet ON PersonalCabinet(user_id);
CREATE INDEX idx_id_account ON PersonalAccount(account_id);
CREATE INDEX idx_name_category ON Category(category_name);
CREATE INDEX idx_id_link ON AccountCabinetLink(account_cabinet_link_id);





EXPLAIN ANALYZE
SELECT ad.city, ad.street, ad.house, ad.apartment, pc.phone_number
FROM PersonalCabinet pc
JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
ORDER BY ad.city, ad.street, ad.house, ad.apartment ;



EXPLAIN ANALYZE
SELECT pa.account_id, pc.first_name, pc.last_name, d.category_name, d.debt
FROM Debt d
JOIN AccountCabinetLink ac ON d.account_id = ac.account_id
JOIN PersonalCabinet pc ON ac.user_id = pc.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
WHERE pc.user_id = 4 AND d.debt > 0;

EXPLAIN ANALYZE
SELECT pa.account_id, c.category_name, SUM(d.debt) AS total_debt
FROM PersonalAccount pa
JOIN Debt d ON pa.account_id = d.account_id
JOIN Category c ON d.category_name = c.category_name
JOIN AccountCabinetLink ac ON pa.account_id = ac.account_id
LEFT JOIN (
    SELECT account_cabinet_link_id, MAX(date_of_payment) AS last_payment_date
    FROM Payment
    GROUP BY account_cabinet_link_id
) p ON ac.account_cabinet_link_id = p.account_cabinet_link_id
WHERE (p.last_payment_date < CURRENT_DATE - INTERVAL '24 months' OR p.last_payment_date IS NULL)
GROUP BY pa.account_id, c.category_name
HAVING SUM(d.debt) > 0
ORDER BY account_id;