with customers as (

    select
        customer_source_record_id,
        customer_id,
        first_name,
        last_name,
        email,
        registration_date,
        loyalty_status,
        acquisition_channel,
        is_active,
        source_updated_at,
        loaded_at

    from {{ ref('snap_crm__customers_scd2') }}
    where dbt_valid_to is null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'customer_id'
        ]) }} as customer_key,

        customer_id,
        customer_source_record_id,

        nullif(
            trim(first_name),
            ''
        ) as first_name,

        nullif(
            trim(last_name),
            ''
        ) as last_name,

        nullif(
            trim(
                concat(
                    coalesce(first_name, ''),
                    ' ',
                    coalesce(last_name, '')
                )
            ),
            ''
        ) as full_name,

        lower(
            trim(email)
        ) as email,

        split_part(
            lower(trim(email)),
            '@',
            2
        ) as email_domain,

        registration_date,

        date_trunc(
            'month',
            registration_date
        )::date as registration_month,

        loyalty_status,
        acquisition_channel,
        is_active,

        case
            when is_active then 'ACTIVE'
            else 'INACTIVE'
        end as customer_status,

        source_updated_at,
        loaded_at

    from customers

)

select *
from final