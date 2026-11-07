-- =====================================================================
-- Семинар. Часть 1: планы и индексы
--
-- Как работаем:
--   * в задании 1 СНАЧАЛА говорим прогноз, ПОТОМ запускаем запрос;
--   * запросы выполняем по одному: курсор на запрос и Ctrl+Enter (на Mac — Cmd+Enter).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. Подготовка (если orders_big ещё нет) — выполнить блоком: выделить и Alt+X
--    Таблица на 5 млн строк создаётся 5–10 секунд.
-- ---------------------------------------------------------------------

drop table if exists orders_big;

create table orders_big with (autovacuum_enabled = false) as
select
    (g - 1) * 1000 + o.order_id      as order_id,
    o.customer_id + 40 * (g % 1000)  as customer_id,
    o.order_created_at
        - ((g * 7919) % 60) * interval '1 day'
        + (g % 1440) * interval '1 minute' as order_created_at,
    o.status,
    o.total_amount
from orders o
cross join generate_series(1, 36000) as g;

alter table orders_big add primary key (order_id);
create index idx_orders_big_status on orders_big (status);
analyze orders_big;

-- какие индексы есть: первичный ключ (order_id) и status
select indexname, indexdef from pg_indexes where tablename = 'orders_big';


-- ---------------------------------------------------------------------
-- 1. Угадай план
--    Для каждого запроса сначала скажите прогноз:
--    прочитает ли база всю таблицу или пойдёт по индексу?
--    Потом выполните и посмотрите на самый нижний шаг плана.
-- ---------------------------------------------------------------------

-- 1.1 Маленькая таблица, поиск по первичному ключу
explain analyze
select * from orders where order_id = 113;

-- 1.2 Большая таблица, поиск по первичному ключу
explain analyze
select * from orders_big where order_id = 2000113;

-- 1.3 Оплаченные заказы (индекс по status есть)
explain analyze
select count(*) from orders_big where status = 'paid';

-- 1.4 Возвращённые заказы (тот же индекс по status)
explain analyze
select order_id, total_amount from orders_big where status = 'returned';

-- Сколько строк под каждым статусом — чтобы проверить себя
select status, count(*), round(100.0 * count(*) / sum(count(*)) over (), 1) as pct
from orders_big group by 1 order by 2 desc;


-- ---------------------------------------------------------------------
-- 2. Почини запрос
--    Поддержке нужны последние 20 заказов клиента 4217.
--    Запрос работает, но медленно. Ускорьте его индексом.
-- ---------------------------------------------------------------------

-- 2.1 Выполните запрос. Посмотрите на нижний шаг плана,
--     Rows Removed by Filter, Buffers и Execution Time.
explain (analyze, buffers)
select order_id, order_created_at, total_amount
from orders_big
where customer_id = 4217
order by order_created_at desc
limit 20;

-- 2.2 Создайте индекс, который найдёт заказы клиента
--     сразу отсортированными по дате. Какие столбцы и в каком порядке?
create index idx_orders_big_customer_created
    on orders_big (/* TODO */);

-- 2.3 Выполните запрос из шага 2.1 ещё раз и сравните план, Buffers и время.


-- ---------------------------------------------------------------------
-- Уборка (в конце семинара)
-- ---------------------------------------------------------------------
-- drop table if exists orders_big;
