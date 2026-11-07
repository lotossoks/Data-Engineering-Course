{{ config(materialized='table', distributed_replicated=true) }}
with confirmed as (
    select *
         , row_number() over (
               partition by customer_id
               order by ordered_at, order_id
           ) as rn
    from {{ ref('fct_orders') }}
    where is_confirmed
), totals as (
    select customer_id
         , count(*) as confirmed_orders_count
         , sum(order_amount) as confirmed_revenue
    from confirmed
    group by customer_id
)
select
    c.customer_id
     , c.registered_at
     , c.registration_date
     , c.city
     , c.acquisition_channel
     , f.order_id as first_confirmed_order_id
     , f.ordered_at as first_confirmed_at
     , coalesce(t.confirmed_orders_count, 0) as confirmed_orders_count
     , coalesce(t.confirmed_revenue, 0) as confirmed_revenue
     , coalesce(t.confirmed_orders_count, 0) > 0 as is_buyer
from {{ ref('stg_shop__customers') }} c
left join totals t
  on t.customer_id = c.customer_id
left join confirmed f
  on f.customer_id = c.customer_id
 and f.rn = 1