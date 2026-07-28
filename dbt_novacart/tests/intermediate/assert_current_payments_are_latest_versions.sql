with ranked_staging_payments as (

    select
        payment_id,
        payment_source_record_id,

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

expected_current_payments as (

    select
        payment_id,
        payment_source_record_id

    from ranked_staging_payments
    where record_rank = 1

),

actual_current_payments as (

    select
        payment_id,
        payment_source_record_id

    from {{ ref('int_payment_gateway__payments_current') }}

)

select
    coalesce(
        expected.payment_id,
        actual.payment_id
    ) as payment_id,

    expected.payment_source_record_id
        as expected_source_record_id,

    actual.payment_source_record_id
        as actual_source_record_id

from expected_current_payments expected

full outer join actual_current_payments actual
    on expected.payment_id = actual.payment_id

where expected.payment_id is null
   or actual.payment_id is null
   or expected.payment_source_record_id
      <> actual.payment_source_record_id