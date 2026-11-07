-- Читаем фактически загруженные PostgreSQL-строки, а не генерируем похожие заново.
create database if not exists shop;
drop table if exists shop.orders_large;
drop table if exists shop.orders_small;
create table shop.orders_large (
    order_id UInt64,
    customer_id UInt64,
    shop_id UInt32,
    order_created_at DateTime('UTC'),
    status LowCardinality(String),
    total_amount Decimal(18,2)
) engine = MergeTree
partition by toYYYYMM(order_created_at)
order by (shop_id, order_created_at, order_id);
insert into shop.orders_large
select order_id, customer_id, shop_id, order_created_at, status, total_amount
from postgresql('postgres:5432', 'shop', 'orders_large', 'student', 'studentpass');
create table shop.orders_small as shop.orders_large;
insert into shop.orders_small
select * from shop.orders_large where order_id <= 1000;
-- Подготовка учебных таблиц, не регулярная production-рекомендация.
optimize table shop.orders_large final;
optimize table shop.orders_small final;
create table if not exists shop.seed_ready (version UInt8) engine = TinyLog;
truncate table shop.seed_ready;
insert into shop.seed_ready values (1);
