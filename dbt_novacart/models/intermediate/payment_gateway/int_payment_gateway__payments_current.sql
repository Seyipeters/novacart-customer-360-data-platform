with ranked_payments as (

    select
        *,

        row_number() over (
            partition by payment_id
            order by
                source_record_arrived_at desc,
                loaded_at desc,
                source_file_last_modified desc,
                source_file_row_number desc,
                payment_source_record_id desc
        ) as record_rank

    from {{ ref('stg_payment_gateway__payments') }}

),

current_payments as (

    select
        payment_source_record_id,
        payment_id,
        order_id,
        payment_attempt_number,

        payment_method,
        payment_status,

        payment_amount,
        captured_amount,
        currency,

        payment_timestamp,
        gateway_reference,
        failure_reason,
        source_record_arrived_at,

        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from ranked_payments
    where record_rank = 1

)

select *
from current_payments