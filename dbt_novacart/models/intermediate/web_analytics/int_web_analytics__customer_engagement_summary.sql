with web_events as (

    select
        event_id,
        customer_id,
        campaign_id,
        order_id,
        product_id,
        event_timestamp,
        event_type,
        page_url,
        device_type,
        browser,
        traffic_source,
        source_record_arrived_at,
        loaded_at

    from {{ ref('stg_web_analytics__web_events') }}

    where customer_id is not null

),

customer_engagement_summary as (

    select
        customer_id,

        count(*) as total_web_events,

        count(distinct event_type)
            as event_type_count,

        count(distinct campaign_id)
            as campaigns_engaged_count,

        count(distinct order_id)
            as attributed_order_count,

        count(distinct product_id)
            as products_engaged_count,

        count(distinct page_url)
            as pages_visited_count,

        count(distinct device_type)
            as device_type_count,

        count(distinct browser)
            as browser_count,

        count(distinct traffic_source)
            as traffic_source_count,

        min(event_timestamp)
            as first_event_at,

        max(event_timestamp)
            as latest_event_at,

        max(source_record_arrived_at)
            as latest_source_record_arrived_at,

        max(loaded_at)
            as latest_loaded_at

    from web_events

    group by customer_id

)

select *
from customer_engagement_summary