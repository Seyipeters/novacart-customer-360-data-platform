with returns as (

    select
        return_id,
        order_id,
        order_item_id,
        customer_id,
        product_id,

        return_date,
        return_quantity,

        return_reason,
        return_status,

        refund_amount,
        currency,

        source_created_at,
        loaded_at

    from {{ ref('int_ecommerce__returns_current') }}

),

customers as (

    select
        customer_id,
        customer_key

    from {{ ref('dim_customers') }}

),

products as (

    select
        product_id,
        product_key

    from {{ ref('dim_products') }}

),

final as (

    select
        returns.return_id,

        returns.order_id,
        returns.order_item_id,

        customers.customer_key,
        returns.customer_id,

        products.product_key,
        returns.product_id,

        returns.return_date,
        returns.return_quantity,

        trim(returns.return_reason) as return_reason,
        trim(returns.return_status) as return_status,

        returns.refund_amount,
        upper(trim(returns.currency)) as currency,

        returns.source_created_at,
        returns.loaded_at

    from returns

    left join customers
        on returns.customer_id = customers.customer_id

    left join products
        on returns.product_id = products.product_id

)

select *
from final