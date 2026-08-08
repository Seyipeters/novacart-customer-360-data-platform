{% set orders_relation = ref('int_ecommerce__orders_current') %}

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=
            "date_trunc(
                'year',
                (
                    select min(order_date)
                    from " ~ orders_relation ~ "
                )
            )",
        end_date=
            "dateadd(
                year,
                1,
                date_trunc(
                    'year',
                    (
                        select max(order_date)
                        from " ~ orders_relation ~ "
                    )
                )
            )"
    ) }}

),

final as (

    select
        to_number(
            to_char(date_day, 'YYYYMMDD')
        ) as date_key,

        date_day,

        day(date_day) as day_of_month,
        dayofweekiso(date_day) as day_of_week_number,
        trim(to_char(date_day, 'Day')) as day_name,
        dayofyear(date_day) as day_of_year,

        weekiso(date_day) as iso_week_number,
        yearofweekiso(date_day) as iso_week_year,

        month(date_day) as month_number,
        trim(to_char(date_day, 'Month')) as month_name,

        to_number(
            to_char(date_day, 'YYYYMM')
        ) as year_month_number,

        to_char(date_day, 'YYYY-MM') as year_month,

        quarter(date_day) as quarter_number,

        'Q' || quarter(date_day)
            as quarter_name,

        year(date_day) as year_number,

        date_trunc('week', date_day)::date
            as week_start_date,

        date_trunc('month', date_day)::date
            as month_start_date,

        last_day(date_day, 'month')
            as month_end_date,

        date_trunc('quarter', date_day)::date
            as quarter_start_date,

        last_day(date_day, 'quarter')
            as quarter_end_date,

        date_trunc('year', date_day)::date
            as year_start_date,

        last_day(date_day, 'year')
            as year_end_date,

        case
            when dayofweekiso(date_day) in (6, 7)
                then true
            else false
        end as is_weekend

    from date_spine

)

select *
from final