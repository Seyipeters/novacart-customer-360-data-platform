with ranked_staging_customers as (

    select
        customer_id,
        customer_source_record_id,

        row_number() over (
            partition by customer_id
            order by
                source_updated_at desc,
                loaded_at desc,
                source_file_last_modified desc,
                source_file_row_number desc,
                customer_source_record_id desc
        ) as record_rank

    from {{ ref('stg_crm__customers') }}

),

expected_current_customers as (

    select
        customer_id,
        customer_source_record_id

    from ranked_staging_customers
    where record_rank = 1

),

actual_current_customers as (

    select
        customer_id,
        customer_source_record_id

    from {{ ref('int_crm__customers_current') }}

)

select
    coalesce(
        expected.customer_id,
        actual.customer_id
    ) as customer_id,

    expected.customer_source_record_id
        as expected_source_record_id,

    actual.customer_source_record_id
        as actual_source_record_id

from expected_current_customers expected

full outer join actual_current_customers actual
    on expected.customer_id = actual.customer_id

where expected.customer_id is null
   or actual.customer_id is null
   or expected.customer_source_record_id
      <> actual.customer_source_record_id