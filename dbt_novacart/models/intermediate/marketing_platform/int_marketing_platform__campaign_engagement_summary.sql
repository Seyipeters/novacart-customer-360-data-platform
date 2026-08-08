with campaigns as (

    select *
    from {{ ref('stg_marketing_platform__campaigns') }}

),

web_events as (

    select *
    from {{ ref('stg_web_analytics__web_events') }}

),

campaign_engagement_summary as (

    select
        c.campaign_id,
        c.campaign_name,
        c.campaign_channel,
        c.campaign_objective,
        c.campaign_status,
        c.target_segment,

        c.start_date,
        c.end_date,

        datediff(
            'day',
            c.start_date,
            c.end_date
        ) + 1 as campaign_duration_days,

        c.budget_amount,
        c.currency,

        count(w.event_id) as total_web_events,

        count(distinct w.customer_id)
            as unique_customers_engaged,

        count(distinct w.order_id)
            as attributed_order_count,

        count(distinct w.product_id)
            as unique_products_engaged,

        count(distinct w.page_url)
            as unique_pages_visited,

        count(distinct w.traffic_source)
            as traffic_source_count,

        min(w.event_timestamp)
            as first_event_at,

        max(w.event_timestamp)
            as latest_event_at,

        round(
            c.budget_amount
            / nullif(count(distinct w.order_id), 0),
            2
        ) as budget_per_attributed_order,

        c.source_updated_at
            as campaign_source_updated_at,

        max(w.source_record_arrived_at)
            as latest_web_event_source_updated_at,

        greatest(
            c.loaded_at,
            coalesce(max(w.loaded_at), c.loaded_at)
        ) as latest_loaded_at

    from campaigns as c

    left join web_events as w
        on c.campaign_id = w.campaign_id

    group by
        c.campaign_id,
        c.campaign_name,
        c.campaign_channel,
        c.campaign_objective,
        c.campaign_status,
        c.target_segment,
        c.start_date,
        c.end_date,
        c.budget_amount,
        c.currency,
        c.source_updated_at,
        c.loaded_at

)

select *
from campaign_engagement_summary