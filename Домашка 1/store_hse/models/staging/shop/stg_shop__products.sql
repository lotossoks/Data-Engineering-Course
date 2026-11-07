select
    product_id
     , category
     , brand
     , product_name
from {{ source('shop', 'products') }}