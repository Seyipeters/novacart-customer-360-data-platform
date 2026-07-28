with ranked_customers as (

    select
        *,

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

current_customers as (

    select
        * exclude (record_rank)

    from ranked_customers
    where record_rank = 1

)

select *
from current_customers