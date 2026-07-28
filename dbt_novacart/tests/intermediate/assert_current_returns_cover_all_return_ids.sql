with staging_returns as (

    select
        count(distinct return_id) as distinct_return_count

    from {{ ref('stg_ecommerce__returns') }}
    where return_id is not null

),

current_returns as (

    select
        count(*) as current_return_count

    from {{ ref('int_ecommerce__returns_current') }}

)

select
    staging_returns.distinct_return_count,
    current_returns.current_return_count

from staging_returns
cross join current_returns

where staging_returns.distinct_return_count
    <> current_returns.current_return_count