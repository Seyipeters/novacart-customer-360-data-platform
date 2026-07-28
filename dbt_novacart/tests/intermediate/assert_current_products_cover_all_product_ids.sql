with staging_products as (

    select
        count(distinct product_id) as distinct_product_count

    from {{ ref('stg_ecommerce__products') }}
    where product_id is not null

),

current_products as (

    select
        count(*) as current_product_count

    from {{ ref('int_ecommerce__products_current') }}

)

select
    staging_products.distinct_product_count,
    current_products.current_product_count

from staging_products
cross join current_products

where staging_products.distinct_product_count
    <> current_products.current_product_count