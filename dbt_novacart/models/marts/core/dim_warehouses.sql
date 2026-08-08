with warehouses as (

    select distinct
        warehouse_id,
        warehouse_name,
        warehouse_city,
        warehouse_country

    from {{ ref('stg_inventory_system__inventory_daily') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(
            ['warehouse_id']
        ) }} as warehouse_key,

        warehouse_id,
        trim(warehouse_name) as warehouse_name,
        trim(warehouse_city) as warehouse_city,
        trim(warehouse_country) as warehouse_country

    from warehouses

)

select *
from final