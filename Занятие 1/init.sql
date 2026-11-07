-- PostgreSQL выполняет этот скрипт автоматически при первом создании пустого тома.
-- CSV находятся внутри контейнера в /data и загружаются серверной командой COPY.
CREATE TABLE IF NOT EXISTS orders (
    order_id integer PRIMARY KEY,
    order_date date NOT NULL,
    status text NOT NULL CHECK (status IN ('paid', 'returned', 'pending')),
    amount_rub integer NOT NULL CHECK (amount_rub > 0)
);

CREATE TABLE IF NOT EXISTS marketing_attribution (
    order_id integer PRIMARY KEY REFERENCES orders(order_id),
    campaign text NOT NULL
);

COPY orders (order_id, order_date, status, amount_rub)
FROM '/data/orders.csv'
WITH (FORMAT csv, HEADER true);

COPY marketing_attribution (order_id, campaign)
FROM '/data/marketing_attribution.csv'
WITH (FORMAT csv, HEADER true);
