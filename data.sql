-- manager
\COPY PersonalCabinet(first_name, last_name, date_of_birth, phone_number, email) FROM 'C:\datas\cursova\datas\cabinet.csv' DELIMITER ';' CSV HEADER;

\COPY Address(city, street, house, apartment) FROM 'C:\datas\cursova\datas\addresses.csv' DELIMITER ';' CSV HEADER;

\COPY PersonalAccount(account_number, address_id) FROM 'C:\datas\cursova\datas\account.csv' DELIMITER ';' CSV HEADER;

\COPY AccountCabinetLink(user_id, account_id) FROM 'C:\datas\cursova\datas\linked.csv' DELIMITER ';' CSV HEADER;

\COPY ServiceRate(cost_per_unit_of_service) FROM 'C:\datas\cursova\datas\tariff.csv' DELIMITER ';' CSV HEADER;

\COPY Category(category_name, is_counter_needed, service_rate_id) FROM 'C:\datas\cursova\datas\category.csv' DELIMITER ';' CSV HEADER;

-- accountant
\COPY Card(card_number, bank) FROM 'C:\datas\cursova\datas\card.csv' DELIMITER ';' CSV HEADER;

\COPY PaymentTopUp(date_of_top_up, top_up_sum, user_id, card_id) FROM 'C:\datas\cursova\datas\topup.csv' DELIMITER ';' CSV HEADER;

\COPY Debt(account_id, category_name) FROM 'C:\datas\cursova\datas\debt.csv' DELIMITER ';' CSV HEADER;

\COPY Payment(date_of_payment, payment_sum, category_name, account_cabinet_link_id) FROM 'C:\datas\cursova\datas\payment.csv' DELIMITER ';' CSV HEADER;

-- counter_master
\COPY Counter(number_on_counter_now, number_on_counter_then, account_id, counter_type) FROM 'C:\datas\cursova\datas\counter.csv' DELIMITER ';' CSV HEADER;
