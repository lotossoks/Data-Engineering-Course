-- База shop, схема public; init запускается при отсутствии seed_ready.
drop table if exists orders_source;
drop table if exists customers;
create table orders_source (
    order_id bigint not null,
    customer_id bigint not null,
    shop_id integer not null,
    order_created_at timestamp not null,
    status text not null,
    total_amount numeric(18,2) not null
) distributed by (order_id);
insert into orders_source
select i, 1 + (i * 7919 % 100000),
       (1 + ((i * 69621 % 2147483647) % 100))::integer,
       timestamp '2024-01-01' + ((i * 48271 % 2147483647) % 730) * interval '1 day'
           + (i % 86400) * interval '1 second',
       case when i % 10 = 0 then 'pending' else 'paid' end,
       ((10000 + i % 990001)::numeric / 100)::numeric(18,2)
from generate_series(1::bigint, 1000000::bigint) s(i);
create table customers (customer_id bigint not null, city text not null)
distributed by (customer_id);
insert into customers
select i, 'city_' || (i % 10)::text from generate_series(1,100000) s(i);
analyze orders_source;
analyze customers;
create table if not exists seed_ready (version integer) distributed randomly;
truncate table seed_ready;
insert into seed_ready values (1);
