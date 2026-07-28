with ranked_staging_returns as (

    select
        return_id,
        return_source_record_id,

        row_number() over (
            partition by return_id
            order by
                loaded_at desc,
                source_file_last_modified desc,
                source_file_row_number desc,
                return_source_record_id desc
        ) as record_rank

    from {{ ref('stg_ecommerce__returns') }}

),

expected_current_returns as (

    select
        return_id,
        return_source_record_id

    from ranked_staging_returns
    where record_rank = 1

),

actual_current_returns as (

    select
        return_id,
        return_source_record_id

    from {{ ref('int_ecommerce__returns_current') }}

)

select
    coalesce(
        expected.return_id,
        actual.return_id
    ) as return_id,

    expected.return_source_record_id
        as expected_source_record_id,

    actual.return_source_record_id
        as actual_source_record_id

from expected_current_returns expected

full outer join actual_current_returns actual
    on expected.return_id = actual.return_id

where expected.return_id is null
   or actual.return_id is null
   or expected.return_source_record_id
      <> actual.return_source_record_id