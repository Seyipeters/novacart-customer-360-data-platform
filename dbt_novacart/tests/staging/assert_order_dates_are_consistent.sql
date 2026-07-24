select
    order_source_record_id,
    order_id,
    order_timestamp,
    order_date
from {{ ref('stg_ecommerce__orders') }}
where order_date <> order_timestamp::date
    or source_updated_at < order_timestamp