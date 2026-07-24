with source as (

    select *
    from {{ source('raw', 'campaigns') }}

),

cleaned as (

    select

        sha2(
            concat_ws(
                '|',
                coalesce(source_file_content_key, ''),
                source_file_row_number::varchar
            ),
            256
        ) as campaign_source_record_id,

        trim(campaign_id) as campaign_id,
        trim(campaign_name) as campaign_name,
        upper(trim(campaign_channel)) as campaign_channel,
        upper(trim(campaign_objective)) as campaign_objective,
        upper(trim(target_segment)) as target_segment,

        start_date,
        end_date,

        budget_amount::number(18, 2) as budget_amount,
        upper(trim(currency)) as currency,
        upper(trim(campaign_status)) as campaign_status,

        updated_at as source_updated_at,

        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from source

)

select *
from cleaned
