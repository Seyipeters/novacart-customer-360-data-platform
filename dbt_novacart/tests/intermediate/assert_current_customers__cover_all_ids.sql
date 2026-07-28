with staging_customers as (

    select
        count(distinct customer_id) as distinct_customer_count

    from {{ ref('stg_crm__customers') }}
    where customer_id is not null

),

current_customers as (

    select
        count(*) as current_customer_count

    from {{ ref('int_crm__customers_current') }}

)

select
    staging_customers.distinct_customer_count,
    current_customers.current_customer_count

from staging_customers
cross join current_customers

where staging_customers.distinct_customer_count
    <> current_customers.current_customer_count