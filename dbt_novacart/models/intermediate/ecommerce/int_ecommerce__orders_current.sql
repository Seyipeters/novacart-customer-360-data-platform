WITH orders as (

    select * 
    from {{ ref('stg_ecommerce__orders') }}
),

ranked as (

    select *,
        row_number() over (
            partition by (order_id)
            order by 
            source_updated_at desc, 
            loaded_at desc,                 
            source_file_last_modified desc,
            source_file_row_number desc,
            order_source_record_id desc
        ) as order_recency_rank

    from orders
)

select * 
from ranked
where order_recency_rank = 1