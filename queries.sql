-- 1 Користувачі, які мають в своємо кабінеті адреси з Києвом
SELECT DISTINCT pc.first_name ||' '|| pc.last_name AS full_name, pc.email, ad.street, ad.apartment FROM Address ad JOIN PersonalAccount pa ON ad.address_id = pa.address_id
JOIN AccountCabinetLink ac ON ac.account_id = pa.account_id
JOIN PersonalCabinet pc ON pc.user_id = ac.user_id
WHERE ad.city = 'Kyiv';

-- 2 Максимальне поповнення
SELECT pc.first_name, pc.last_name, MAX(pt.top_up_sum) AS max_top_up
FROM PersonalCabinet pc
JOIN PaymentTopUp pt ON pc.user_id = pt.user_id
GROUP BY pc.user_id
ORDER BY max_top_up DESC;

-- 3 Кількість поповнень за певною карткою
SELECT c.card_number, COUNT(pt.card_id) FROM Card c JOIN PaymentTopUp pt ON c.card_id = pt.card_id GROUP BY (c.card_number) HAVING COUNT(pt.card_id) >= 2;

-- 4 Кількість аккаунтів по всім вулицям.
SELECT ad.street, COUNT(DISTINCT pa.account_id) AS account_count FROM Address ad
JOIN PersonalAccount pa ON ad.address_id = pa.address_id
GROUP BY ad.street
ORDER BY account_count DESC;




-- 5 Три міста де найменший тотальний борг
SELECT ad.city, SUM(d.debt) AS total_debt FROM Debt d
JOIN PersonalAccount pa ON d.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
GROUP BY ad.city
ORDER BY SUM(d.debt)
LIMIT 3;

-- 6 Вивід категорій, тотального боргу якщо тариф більше 20
SELECT c.category_name, SUM(d.debt) AS total_debt, sr.cost_per_unit_of_service
FROM Debt d 
JOIN Category c ON d.category_name = c.category_name
JOIN ServiceRate sr ON sr.service_rate_id = c.service_rate_id 
GROUP BY c.category_name, sr.cost_per_unit_of_service
HAVING sr.cost_per_unit_of_service >= 20;

-- 7 Вивід аккаунтів та їх боргів по категоріям
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


-- 8 Вивід картки та користувача/кількості користувачів, які користувалися нею, для оплати за адресу де є вулиця "Bankivska".
SELECT c.card_number,
    CASE
        WHEN COUNT(DISTINCT pc.user_id) = 1 THEN MAX(pc.first_name || ' ' || pc.last_name)
        ELSE CAST(COUNT(DISTINCT pc.user_id) AS VARCHAR)
    END AS user_info
FROM Card c
JOIN PaymentTopUp pt ON c.card_id = pt.card_id
JOIN PersonalCabinet pc ON pt.user_id = pc.user_id
JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
WHERE ad.street = 'Bankivska'
GROUP BY c.card_number;


-- 9 Вивід категорій, кількості аккаунтів та оплат по цим категоріям, здійснених за останні 5 місяців.
SELECT p.category_name, SUM(p.payment_sum) AS total_payment, COUNT(DISTINCT pa.account_id) AS number_of_accounts
FROM Payment p
JOIN AccountCabinetLink ac ON p.account_cabinet_link_id = ac.account_cabinet_link_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
WHERE p.date_of_payment > CURRENT_DATE - INTERVAL '5 month'
GROUP BY p.category_name;



-- 10 Вивід усіх банків у яких у назві є Pri, та номера телефонів пов'язані із цим CVV
SELECT c.bank, pc.phone_number FROM Card c
JOIN PaymentTopUp pt ON c.card_id = pt.card_id
JOIN PersonalCabinet pc ON pt.user_id = pc.user_id
WHERE c.bank LIKE 'Pri%';


-- 11 Вивід аккаунт ід, повного ім'я, назву категорії та борг по ній, якщо існує
SELECT pa.account_id, pc.first_name, pc.last_name, d.category_name, d.debt
FROM Debt d
JOIN AccountCabinetLink ac ON d.account_id = ac.account_id
JOIN PersonalCabinet pc ON ac.user_id = pc.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
WHERE pc.user_id = 4 AND d.debt > 0;

-- UPDATE Payment
-- SET payment_sum = 50
-- WHERE account_cabinet_link_id = 134 AND category_name = 'Gas supply';


-- 12 Кількість користувачів у яких є борг
SELECT COUNT(DISTINCT pc.user_id) AS number_of_users_with_outstanding_debt
FROM PersonalCabinet pc
JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
JOIN Debt d ON ac.account_id = d.account_id
WHERE d.debt > 0;

-- 13 Акаунти для певного юзера
SELECT pc.first_name || ' ' || pc.last_name AS full_name, pa.account_id
FROM PersonalCabinet pc
JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
WHERE pc.user_id = 37;


-- 14 Адреса та номер телефону
SELECT ad.city, ad.street, ad.house, ad.apartment, pc.phone_number
FROM PersonalCabinet pc
JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
JOIN PersonalAccount pa ON ac.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
ORDER BY ad.city, ad.street, ad.house, ad.apartment ;


-- 15 Сума всіх оплат за категорії, які потребують лічильники.
SELECT c.counter_type, SUM(p.payment_sum) AS total_payment
FROM Counter c
JOIN PersonalAccount pa ON c.account_id = pa.account_id
JOIN Payment p ON pa.account_id = p.account_cabinet_link_id
GROUP BY c.counter_type;


-- 16 Сума всіх поповнень для користувачів, яким менше 25 років.
SELECT pc.first_name, pc.last_name, SUM(pt.top_up_sum) AS total_top_up FROM PersonalCabinet pc
JOIN PaymentTopUp pt ON pc.user_id = pt.user_id
WHERE (CURRENT_DATE - pc.date_of_birth) / 365 <= 25
GROUP BY pc.user_id;

-- 17 (З підзапитом) Вивід користувача, де номер картки починається на "60" і сума поповнення більше 100
SELECT pc.first_name, pc.last_name, pt.date_of_top_up, pt.top_up_sum
FROM PersonalCabinet pc
JOIN PaymentTopUp pt ON pc.user_id = pt.user_id
WHERE pt.card_id IN (
    SELECT card_id
    FROM Card
    WHERE card_number LIKE '60%'
)
AND pt.top_up_sum > 100;

--18 (З підзапитом) Вивід усіх міст, в яких заборгованість по "Building management" більше ніж середня.
SELECT ad.city, SUM(d.debt) AS total_debt
FROM Debt d
JOIN PersonalAccount pa ON d.account_id = pa.account_id
JOIN Address ad ON pa.address_id = ad.address_id
WHERE d.category_name = 'Building management'
GROUP BY ad.city
HAVING SUM(d.debt) > (SELECT AVG(total_debt) 
                      FROM (SELECT SUM(d.debt) AS total_debt
                            FROM Debt d
                            JOIN PersonalAccount pa ON d.account_id = pa.account_id
                            WHERE d.category_name = 'Building management'
                            GROUP BY pa.account_id) AS subquery);

--19 (З підзапитом) Вивід вулиці та найпопулярнішого домену електронної пошти
SELECT ad.street, 
    (SELECT email_domain 
     FROM (SELECT SUBSTRING(pc.email FROM POSITION('@' IN pc.email) + 1) AS email_domain
           FROM PersonalCabinet pc JOIN AccountCabinetLink ac ON pc.user_id = ac.user_id
           JOIN PersonalAccount pa ON ac.account_id = pa.account_id
           JOIN Address a ON pa.address_id = a.address_id
           WHERE a.street = ad.street
           GROUP BY email_domain
           ORDER BY COUNT(*) DESC
           LIMIT 1) AS subquery) AS most_popular_email_domain
FROM Address ad
GROUP BY ad.street;



-- 20 Вивід ід аккаунту та його адрес, якщо немає жодного ліччильника
SELECT pa.account_id, ad.city, ad.street, ad.house, ad.apartment FROM PersonalAccount pa
JOIN Address ad ON pa.address_id = ad.address_id
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Counter c
        WHERE c.account_id = pa.account_id
    );