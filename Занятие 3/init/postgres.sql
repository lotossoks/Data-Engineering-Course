-- Синтетический набор: одна строка на заказ. Даты UTC, два года истории.
create table orders_large (
    order_id bigint not null,
    customer_id bigint not null,
    shop_id integer not null,
    order_created_at timestamp not null,
    status text not null,
    total_amount numeric(18,2) not null,
    primary key (order_id)
);
insert into orders_large
select i, 1 + (i * 7919 % 100000),
       (1 + ((i * 69621 % 2147483647) % 100))::integer,
       timestamp '2024-01-01' + ((i * 48271 % 2147483647) % 730) * interval '1 day'
           + (i % 86400) * interval '1 second',
       case when i % 10 = 0 then 'pending' else 'paid' end,
       ((10000 + i % 990001)::numeric / 100)::numeric(18,2)
from generate_series(1::bigint, 5000000::bigint) s(i);
create table orders_small (like orders_large including all);
insert into orders_small select * from orders_large where order_id <= 1000;
analyze orders_large;
analyze orders_small;
create table seed_ready (version integer primary key);
insert into seed_ready values (1);
