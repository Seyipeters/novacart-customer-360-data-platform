with staging_payments as (

    select
        count(distinct payment_id) as distinct_payment_count

    from {{ ref('stg_payment_gateway__payments') }}
    where payment_id is not null

),

current_payments as (

    select
        count(*) as current_payment_count

    from {{ ref('int_payment_gateway__payments_current') }}

)

select
    staging_payments.distinct_payment_count,
    current_payments.current_payment_count

from staging_payments
cross join current_payments

where staging_payments.distinct_payment_count
    <> current_payments.current_payment_count