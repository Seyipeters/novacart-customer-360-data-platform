with expected_latest_dates as (

    select
        warehouse_id,
        product_id,
        max(inventory_date) as expected_latest_inventory_date

    from {{ ref('stg_inventory_system__inventory_daily') }}

    group by
        warehouse_id,
        product_id

),

current_inventory as (

    select *
    from {{ ref('int_inventory_system__inventory_current') }}

)

select
    current_inventory.warehouse_id,
    current_inventory.product_id,
    current_inventory.inventory_date,
    expected_latest_dates.expected_latest_inventory_date

from current_inventory

inner join expected_latest_dates
    on current_inventory.warehouse_id =
       expected_latest_dates.warehouse_id

    and current_inventory.product_id =
        expected_latest_dates.product_id

where current_inventory.inventory_date
    <> expected_latest_dates.expected_latest_inventory_date