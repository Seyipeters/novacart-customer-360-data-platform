with inventory_daily as (

    select *
    from {{ ref('stg_inventory_system__inventory_daily') }}

),

ranked_inventory as (

    select
        *,

        row_number() over (
            partition by
                warehouse_id,
                product_id

            order by
                inventory_date desc,
                source_updated_at desc,
                loaded_at desc,
                inventory_source_record_id desc
        ) as inventory_recency_rank

    from inventory_daily

),

current_inventory as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'warehouse_id',
            'product_id'
        ]) }} as inventory_current_id,

        inventory_date,
        warehouse_id,
        product_id,
        warehouse_name,
        warehouse_city,
        warehouse_country,
        opening_stock,
        received_quantity,
        sold_quantity,
        damaged_quantity,
        closing_stock,
        unit_cost,
        inventory_value,
        stockout_flag,
        reorder_flag,
        source_updated_at,
        source_file,
        source_file_row_number,
        loaded_at

    from ranked_inventory

    where inventory_recency_rank = 1

)

select *
from current_inventory