with ranked_returns as (

    select
        *,

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

current_returns as (

    select
        * exclude (record_rank)

    from ranked_returns
    where record_rank = 1

)

select *
from current_returns