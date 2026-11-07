with items as (
    select order_id
         , sum(line_amount) as items_amount
    from {{ ref('fct_order_items') }}
    group by order_id
)
select
    o.order_id
     , o.order_amount
     , i.items_amount
from {{ ref('fct_orders') }} o
left join items i
  on o.order_id = i.order_id
where o.order_amount <> coalesce(i.items_amount, 0)