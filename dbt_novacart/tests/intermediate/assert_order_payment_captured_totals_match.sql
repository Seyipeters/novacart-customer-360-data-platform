with expected_captured_amounts as (

    select
        order_id,
        round(sum(captured_amount), 2)
            as expected_captured_amount

    from {{ ref('int_payment_gateway__payments_current') }}
    group by order_id

),

actual_captured_amounts as (

    select
        order_id,
        round(total_captured_amount, 2)
            as actual_captured_amount

    from {{ ref('int_payment_gateway__order_payment_summary') }}

)

select
    actual.order_id,
    actual.actual_captured_amount,
    expected.expected_captured_amount

from actual_captured_amounts actual

inner join expected_captured_amounts expected
    on actual.order_id = expected.order_id

where abs(
    actual.actual_captured_amount
    - expected.expected_captured_amount
) >= 0.01