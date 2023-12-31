DROP TABLE Payment, AccountCabinetLink, Debt, ServiceRate, Counter, Category, PersonalAccount, Address, PaymentTopUp, PersonalCabinet, Card;

CREATE TABLE Card (
    card_id SERIAL PRIMARY KEY,
    card_number VARCHAR(16) NOT NULL UNIQUE,
    bank VARCHAR(70) NOT NULL
);

CREATE TABLE PersonalCabinet (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= (CURRENT_DATE - INTERVAL '18 year')),
    phone_number VARCHAR(13) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    balance NUMERIC(10, 2) NOT NULL CHECK (balance >= 0) DEFAULT 0
);

CREATE TABLE PaymentTopUp (
    payment_top_up_id SERIAL PRIMARY KEY,
    date_of_top_up DATE NOT NULL CHECK (date_of_top_up <= CURRENT_DATE),
    top_up_sum NUMERIC(10, 2) NOT NULL CHECK (top_up_sum > 0),
    card_id INTEGER NOT NULL REFERENCES Card(card_id)  ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES PersonalCabinet(user_id)  ON DELETE CASCADE
);

CREATE TABLE Address (
    address_id SERIAL PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    street VARCHAR(50) NOT NULL,
    house VARCHAR(10) NOT NULL,
    apartment INT NOT NULL,
    CONSTRAINT address_unique UNIQUE (city, street, house, apartment)
);

CREATE TABLE PersonalAccount (
    account_id SERIAL PRIMARY KEY,
    account_number BIGINT NOT NULL UNIQUE CHECK (account_number > 1000000000 AND account_number < 9999999999),
    address_id INTEGER NOT NULL UNIQUE REFERENCES Address(address_id)  ON DELETE CASCADE
);

CREATE TABLE Counter (
    counter_id SERIAL PRIMARY KEY,
    number_on_counter_now INT NOT NULL CHECK (number_on_counter_now >= 0),
    number_on_counter_then INT NOT NULL CHECK (number_on_counter_then <= number_on_counter_now),
    account_id INT NOT NULL REFERENCES PersonalAccount(account_id)  ON DELETE CASCADE,
    counter_type VARCHAR(70) NOT NULL,
    CONSTRAINT counter_unique UNIQUE (account_id, counter_type)
);

CREATE TABLE ServiceRate (
    service_rate_id SERIAL PRIMARY KEY,
    cost_per_unit_of_service NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Category (
    category_name VARCHAR(70) PRIMARY KEY,
    is_counter_needed BOOLEAN NOT NULL,
    service_rate_id INT NOT NULL UNIQUE REFERENCES ServiceRate(service_rate_id)  ON DELETE CASCADE
);

CREATE TABLE Debt (
    debt_id SERIAL PRIMARY KEY,
    debt NUMERIC(10, 2) CHECK (debt >= 0) DEFAULT 0,
    category_name VARCHAR(70) NOT NULL REFERENCES Category(category_name)  ON DELETE CASCADE,
    account_id INTEGER NOT NULL REFERENCES PersonalAccount(account_id)  ON DELETE CASCADE,
    CONSTRAINT debt_unique UNIQUE (category_name, account_id)
);

CREATE TABLE AccountCabinetLink (
    account_cabinet_link_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES PersonalAccount(account_id)  ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES PersonalCabinet(user_id)  ON DELETE CASCADE,
    CONSTRAINT account_cabinet_unique UNIQUE (user_id, account_id)
);

CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    date_of_payment DATE NOT NULL CHECK (date_of_payment <= CURRENT_DATE),
    payment_sum NUMERIC(10, 2) NOT NULL CHECK (payment_sum > 0),
    category_name VARCHAR(70) NOT NULL,
    account_cabinet_link_id INTEGER NOT NULL REFERENCES AccountCabinetLink(account_cabinet_link_id) ON DELETE CASCADE
);
