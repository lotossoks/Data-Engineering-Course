{{ config(materialized='table', distributed_by='order_id', orientation='column') }}
select
    i.order_item_id
     , i.order_id
     , i.product_id
     , o.customer_id
     , o.order_date
     , i.quantity
     , i.unit_price
     , i.discount_amount
     , i.gross_amount
     , i.line_amount
     , o.is_confirmed
from {{ ref('stg_shop__order_items') }} i
join {{ ref('fct_orders') }} o
  on o.order_id = i.order_id