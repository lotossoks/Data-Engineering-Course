-- Практика 2. Две простые витрины: контроль оплат и активация клиентов.
-- PostgreSQL 16. Файл можно выполнять повторно: перед вставкой каждая
-- учебная таблица очищается. Между очисткой и вставкой она может быть пуста.

-- 1. Разведка источника.
select count(*) as customers_count from customers;
select count(*) as orders_count from orders;
select count(*) as payments_count from payments;

select o.status, count(*) as orders_count
from orders as o
group by o.status
order by o.status;

-- ============================================================
-- Задание 1. Простой CTE
-- ============================================================
-- Создайте CTE paid_orders с заказами со статусом 'paid'.
-- Оставьте поля order_id, customer_id и total_amount.
-- Выведите первые 10 заказов по возрастанию order_id.

-- Ваш запрос:

select o.customer_id, o.order_id, o.order_created_at,
       lag(o.order_created_at) over (
           partition by o.customer_id
           order by o.order_created_at, o.order_id
       ) as previous_order_created_at
from orders as o
where o.customer_id in (1, 2)
order by o.customer_id, o.order_created_at, o.order_id;


-- ============================================================
-- Задание 2. Оконный count
-- ============================================================
-- Для каждого заказа клиентов 1 и 2 выведите customer_id,
-- order_id и общее число заказов этого клиента.
-- Сохраните отдельную строку для каждого заказа.
-- Отсортируйте по customer_id, order_created_at, order_id.

-- Ваш запрос:
-- Оконный count показывает число заказов клиента, не сворачивая строки заказов.

select o.customer_id, o.order_id,
       count(*) over (partition by o.customer_id) as customer_orders_count
from orders as o
where o.customer_id in (1, 2)
order by o.customer_id, o.order_created_at, o.order_id;


-- ============================================================
-- Задание 3. lag
-- ============================================================
-- Для заказов клиентов 1 и 2 покажите время создания
-- предыдущего заказа того же клиента.
-- Порядок: order_created_at, затем order_id.

-- Ваш запрос:
-- lag берёт дату предыдущего заказа того же клиента; у первого будет null.

select o.customer_id, o.order_id, o.order_created_at,
       lag(o.order_created_at) over (
           partition by o.customer_id
           order by o.order_created_at, o.order_id
       ) as previous_order_created_at
from orders as o
where o.customer_id in (1, 2)
order by o.customer_id, o.order_created_at, o.order_id;


-- ============================================================
-- Задание 4. row_number
-- ============================================================
-- Пронумеруйте заказы клиентов 1 и 2 отдельно для каждого
-- клиента, начиная с единицы.
-- Порядок: order_created_at, затем order_id.
-- Зачем при сортировке нужен order_id?

-- Ваш запрос:
-- row_number нумерует заказы отдельно внутри каждого клиента с единицы.

select o.customer_id, o.order_id, o.order_created_at,
       row_number() over (
           partition by o.customer_id
           order by o.order_created_at, o.order_id
       ) as order_number
from orders as o
where o.customer_id in (1, 2)
order by o.customer_id, o.order_created_at, o.order_id;

-- ============================================================
-- Задание 5. left join и зернистость
-- ============================================================
-- Соедините заказы 113, 116 и 119 с платежными операциями.
-- Выведите order_id, статус и сумму заказа, а также payment_id,
-- статус и сумму операции.
-- Сохраните заказы без найденной операции.
-- Сколько строк получилось для каждого заказа?
-- Почему нельзя просто сложить orders.total_amount после join?

-- Ваш запрос:
select o.order_id, o.status, o.total_amount,
       p.payment_id, p.payment_status, p.amount
from orders as o
left join payments as p on p.order_id = o.order_id
where o.order_id in (113, 116, 119)
order by o.order_id, p.payment_id;

-- 3. Витрина контроля оплат: одна строка на paid-заказ.
create table if not exists practice_paid_order_checks (
    order_id integer primary key,
    customer_id integer not null,
    total_amount numeric(12, 2) not null,
    first_paid_at timestamp,
    successful_operations_count bigint not null,
    successful_amount numeric(12, 2) not null
);

truncate table practice_paid_order_checks;

with successful_payments as (
    select p.order_id,
           min(p.paid_at) as first_paid_at,
           count(*) as successful_operations_count,
           sum(p.amount) as successful_amount
    from payments as p
    where p.payment_status = 'success'
    group by p.order_id
)
insert into practice_paid_order_checks (
    order_id, customer_id, total_amount, first_paid_at,
    successful_operations_count, successful_amount
)
select o.order_id, o.customer_id, o.total_amount,
       sp.first_paid_at,
       coalesce(sp.successful_operations_count, 0),
       coalesce(sp.successful_amount, 0)
from orders as o
left join successful_payments as sp on sp.order_id = o.order_id
where o.status = 'paid';

select order_id, customer_id, total_amount, first_paid_at,
       successful_operations_count, successful_amount
from practice_paid_order_checks
where order_id in (113, 116, 119)
order by order_id;

select count(*) as paid_orders,
       count(*) filter (where successful_operations_count > 0) as confirmed_orders,
       count(*) filter (where successful_operations_count = 0) as paid_without_success,
       sum(total_amount) filter (
           where successful_operations_count > 0
       ) as confirmed_orders_amount
from practice_paid_order_checks;

---- 4. Диагностика истории покупок. Окна сохраняют строки заказов.
---- Этот запрос не входит в загрузку витрины клиентов.
--select pc.customer_id, pc.order_id, pc.first_paid_at,
--       row_number() over (
--           partition by pc.customer_id
--           order by pc.first_paid_at, pc.order_id
--       ) as purchase_number,
--       lag(pc.first_paid_at) over (
--           partition by pc.customer_id
--           order by pc.first_paid_at, pc.order_id
--       ) as previous_paid_at,
--       count(*) over (partition by pc.customer_id) as paid_orders_count,
--       sum(pc.total_amount) over (
--           partition by pc.customer_id
--       ) as paid_orders_amount
--from practice_paid_order_checks as pc
--where pc.successful_operations_count > 0
--  and pc.customer_id in (1, 2)
--order by pc.customer_id, pc.first_paid_at, pc.order_id;

-- 5. Витрина активации: одна строка на клиента, включая клиентов без покупок.
create table if not exists practice_customer_first_purchase (
    customer_id integer primary key,
    city text not null,
    first_paid_order_id integer,
    first_paid_at timestamp,
    hours_to_first_paid numeric(12, 2)
);

truncate table practice_customer_first_purchase;

with numbered_orders as (
    select pc.customer_id, pc.order_id, pc.first_paid_at,
           row_number() over (
               partition by pc.customer_id
               order by pc.first_paid_at, pc.order_id
           ) as purchase_number
    from practice_paid_order_checks as pc
    where pc.successful_operations_count > 0
)
insert into practice_customer_first_purchase (
    customer_id, city, first_paid_order_id, first_paid_at,
    hours_to_first_paid
)
select c.customer_id, c.city, no.order_id, no.first_paid_at,
       round(
           (extract(epoch from (no.first_paid_at - c.registered_at)) / 3600)::numeric,
           2
       )
from customers as c
left join numbered_orders as no
    on no.customer_id = c.customer_id
   and no.purchase_number = 1;

-- 6. Приёмка обеих витрин.
select count(*) as mart_rows,
       count(*) filter (where first_paid_order_id is not null) as activated_customers,
       count(*) filter (where first_paid_order_id is null) as customers_without_purchase
from practice_customer_first_purchase;

select *
from practice_customer_first_purchase
where customer_id in (1, 2, 40)
order by customer_id;

select pc.order_id
from practice_paid_order_checks as pc
where pc.successful_operations_count = 0
order by pc.order_id;

select customer_id, count(*) as rows_per_customer
from practice_customer_first_purchase
group by customer_id
having count(*) > 1;

-- Сверка суммы с независимым запросом к исходным таблицам.
select sum(o.total_amount) as confirmed_orders_amount
from orders as o
where o.status = 'paid'
  and exists (
      select 1
      from payments as p
      where p.order_id = o.order_id
        and p.payment_status = 'success'
  );
