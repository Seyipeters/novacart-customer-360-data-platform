with products as (

    select 
        product_id,
        sku,
        product_name,
        category,
        subcategory,
        brand,
        unit_cost,
        list_price,
        source_updated_at,
        loaded_at
    from {{ ref('int_ecommerce__products_current') }}

),

final as (

    select 
        {{ dbt_utils.generate_surrogate_key (
            ['product_id']) }} as product_key,
        
        product_id,

        upper(trim(sku)) as sku,
        trim(product_name) as product_name,
        trim(category) as category,
        trim(subcategory) as subcategory,
        trim(brand) as brand,

        unit_cost,
        list_price,

        list_price - unit_cost
            as unit_margin_amount,

        case
            when list_price > 0
                then round(
                    (list_price - unit_cost) / list_price,
                    4
                )
            else null
        end as unit_margin_rate,

        source_updated_at,
        loaded_at

    from products
)

select *
from final