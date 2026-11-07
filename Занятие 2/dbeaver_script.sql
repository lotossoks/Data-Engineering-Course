select order_id,
		customer_id,
		total_amount
from orders
where status = 'paid'
limit 10;

select count(*)
from orders;

-- ============================================================
-- Задание 1. Простой CTE
-- ============================================================
-- Создайте CTE paid_orders с заказами со статусом 'paid'.
-- Оставьте поля order_id, customer_id и total_amount.
-- Выведите первые 10 заказов по возрастанию order_id.

with paid_orders as (
select order_id,
		customer_id,
		total_amount
from orders
where status = 'paid')
select  *
from paid_orders
order by order_id
limit 10;


-- ============================================================
-- Задание 2. Оконный count
-- ============================================================
-- Для каждого заказа клиентов 1 и 2 выведите customer_id,
-- order_id и общее число заказов этого клиента.
-- Сохраните отдельную строку для каждого заказа.
-- Отсортируйте по customer_id, order_created_at, order_id.


select customer_id, order_id, count(*) over (partition by customer_id),
 sum(total_amount ) over (partition by customer_id)
from orders o
where o.customer_id in (1, 2)
order by customer_id, order_created_at, order_id;

select customer_id, count(*), sum(o.total_amount)
from orders o
--where o.customer_id in (1, 2)
group by customer_id
order by customer_id;


-- ============================================================
-- Задание 3. lag
-- ============================================================
-- Для заказов клиентов 1 и 2 покажите время создания
-- предыдущего заказа того же клиента.
-- Порядок: order_created_at, затем order_id.


select *
from orders o
where o.customer_id in (1, 2)
order by customer_id, order_id;

-- ============================================================
-- Задание 4. row_number
-- ============================================================
-- Пронумеруйте заказы клиентов 1 и 2 отдельно для каждого
-- клиента, начиная с единицы.
-- Порядок: order_created_at, затем order_id.

-- + таблицу, в которой  для каждого клиента будет 1 первый заказ по
-- order_created_at, затем order_id.


select *
from
(select *,
	row_number()
	over (partition by o.customer_id order by order_created_at, order_id) rn
from orders o) f
where rn = 5;

select *
from  payments p;

with success_payments as (
	select order_id,
			count(*) successful_operations_count,
			min(p.paid_at) first_paid_at,
			sum(p.amount) successful_amount
	from payments p
	where payment_status = 'success'
	group by order_id
	order by order_id)
insert into practice_paid_order_checks (order_id, customer_id, total_amount,
		first_paid_at, successful_operations_count, successful_amount)
select o.order_id,
		customer_id,
		total_amount,
		first_paid_at,
		successful_operations_count,
		successful_amount
from orders o
left join success_payments sp on o.order_id =  sp.order_id
where status = 'paid';

truncate practice_paid_order_checks;

select *
from practice_paid_order_checks;

create table if not exists practice_paid_order_checks
(
	order_id int,
	customer_id int,
	total_amount numeric(10, 2),
	first_paid_at timestamp,
	successful_operations_count int,
	successful_amount numeric(10, 2)
);
