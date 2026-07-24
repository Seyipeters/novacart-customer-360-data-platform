select
    payment_source_record_id,
    payment_id,
    order_id,
    payment_amount,
    captured_amount,
    payment_method,
    payment_status,
    failure_reason,
    payment_timestamp,
    source_record_arrived_at

from {{ ref('stg_payment_gateway__payments') }}
where 
    -- Partial captures without valid reason
    captured_amount > payment_amount  -- captured more than authorized
    or (captured_amount < payment_amount 
       and payment_status = 'COMPLETED')  -- incomplete capture marked complete
    or payment_status = 'FAILED' and captured_amount > 0
    or payment_status in ('FAILED', 'CANCELLED', 'PENDING') and captured_amount > 0 
    or source_record_arrived_at < payment_timestamp
