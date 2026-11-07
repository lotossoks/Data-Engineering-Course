{#https://sqllab.ru/blog/rekursivnye-cte-postgresql/#}

with recursive tree as (
    select category_id
         , parent_category_id
         , category_name
         , null::text as parent_category_name
         , category_name as root_category_name
    from {{ ref('stg_shop__product_categories') }}
    where parent_category_id is null

    union all

    select c.category_id
         , c.parent_category_id
         , c.category_name
         , t.category_name as parent_category_name
         , t.root_category_name
    from {{ ref('stg_shop__product_categories') }} c
    join tree t
      on c.parent_category_id = t.category_id
)
select
    *
from tree