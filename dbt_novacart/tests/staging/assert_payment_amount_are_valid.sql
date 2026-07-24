select
    payment_source_record_id,
    payment_id,
    order_id,
    payment_attempt_number,
    payment_status,
    payment_amount,
    captured_amount,
    payment_timestamp,
    source_record_arrived_at

from {{ ref('stg_payment_gateway__payments') }}

where payment_attempt_number <= 0
   or payment_amount < 0
   or captured_amount < 0
   or captured_amount > payment_amount
   or source_record_arrived_at < payment_timestamp