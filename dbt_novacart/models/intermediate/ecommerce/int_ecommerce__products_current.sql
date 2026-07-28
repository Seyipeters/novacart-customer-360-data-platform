with ranked_products as (

    select
        *,

        row_number() over (
            partition by product_id
            order by
                source_updated_at desc,
                loaded_at desc,
                source_file_last_modified desc,
                source_file_row_number desc,
                product_source_record_id desc
        ) as record_rank

    from {{ ref('stg_ecommerce__products') }}

),

current_products as (

    select
        product_source_record_id,
        product_id,
        sku,
        product_name,
        category,
        subcategory,
        brand,

        unit_cost,
        list_price,

        source_updated_at,

        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from ranked_products
    where record_rank = 1

)

select *
from current_products