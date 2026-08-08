with customer_engagement as (

    select 
        customer_id,

        total_web_events,
        event_type_count,
        campaigns_engaged_count,
        attributed_order_count,
        products_engaged_count,
        pages_visited_count,

        device_type_count,
        browser_count,
        traffic_source_count,

        first_event_at,
        latest_event_at,

        latest_source_record_arrived_at,
        latest_loaded_at

    from  {{ ref ('int_web_analytics__customer_engagement_summary') }}
),

customers as (
    
    select 
        customer_id,
        customer_key

    from {{ ref('dim_customers') }}

),

final as (

    select 
        customers.customer_key,
        customer_engagement.customer_id,

        customer_engagement.total_web_events,
        customer_engagement.event_type_count,
        customer_engagement.campaigns_engaged_count,
        customer_engagement.attributed_order_count,
        customer_engagement.products_engaged_count,
        customer_engagement.pages_visited_count,

        customer_engagement.device_type_count,
        customer_engagement.browser_count,
        customer_engagement.traffic_source_count,

        customer_engagement.first_event_at,
        customer_engagement.latest_event_at,

        customer_engagement.latest_source_record_arrived_at,
        customer_engagement.latest_loaded_at

    from customer_engagement

    left join customers
    on customers.customer_id = customer_engagement.customer_id

)

select *
from final