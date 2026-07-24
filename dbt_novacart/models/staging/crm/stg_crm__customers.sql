with source as (

    select *
    from {{ source('raw', 'customers') }}

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
        ) as customer_source_record_id,

        trim(customer_id) as customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        nullif(trim(phone), '') as phone,

        trim(city) as city,
        trim(region) as region,
        trim(country) as country,
        trim(postal_code) as postal_code,

        registration_date,
        upper(trim(loyalty_status)) as loyalty_status,
        upper(trim(acquisition_channel)) as acquisition_channel,
        is_active,

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
