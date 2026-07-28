with expected_attempt_counts as (

    select
        order_id,
        count(distinct payment_id) as expected_attempt_count

    from {{ ref('int_payment_gateway__payments_current') }}
    group by order_id

),

actual_attempt_counts as (

    select
        order_id,
        payment_attempt_count

    from {{ ref('int_payment_gateway__order_payment_summary') }}

)

select
    actual.order_id,
    actual.payment_attempt_count,
    expected.expected_attempt_count

from actual_attempt_counts actual

inner join expected_attempt_counts expected
    on actual.order_id = expected.order_id

where actual.payment_attempt_count
    <> expected.expected_attempt_count