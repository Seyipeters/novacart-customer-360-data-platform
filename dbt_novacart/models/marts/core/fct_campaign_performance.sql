with campaign_performance as (

    select
        campaign_id,

        budget_amount,

        total_web_events,
        unique_customers_engaged,

        attributed_order_count,
        converted_customer_count,
        captured_payment_order_count,
        refunded_order_count,
        currency_mismatch_order_count,

        total_captured_revenue,
        total_completed_refund_amount,
        net_revenue_after_refunds,

        customer_conversion_rate_pct,
        cost_per_attributed_order,
        average_net_order_value,
        return_on_ad_spend,
        revenue_refund_rate_pct,

        first_attributed_order_event_at,
        latest_attributed_order_event_at,

        campaign_source_updated_at,
        latest_web_event_source_updated_at,
        latest_loaded_at

    from {{ ref('int_marketing_platform__campaign_performance') }}

),

campaigns as (

    select
        campaign_id,
        campaign_key

    from {{ ref('dim_campaigns') }}

),

final as (

    select
        campaigns.campaign_key,
        campaign_performance.campaign_id,

        campaign_performance.budget_amount,

        campaign_performance.total_web_events,
        campaign_performance.unique_customers_engaged,

        campaign_performance.attributed_order_count,
        campaign_performance.converted_customer_count,
        campaign_performance.captured_payment_order_count,
        campaign_performance.refunded_order_count,
        campaign_performance.currency_mismatch_order_count,

        campaign_performance.total_captured_revenue,
        campaign_performance.total_completed_refund_amount,
        campaign_performance.net_revenue_after_refunds,

        campaign_performance.customer_conversion_rate_pct,
        campaign_performance.cost_per_attributed_order,
        campaign_performance.average_net_order_value,
        campaign_performance.return_on_ad_spend,
        campaign_performance.revenue_refund_rate_pct,

        campaign_performance.first_attributed_order_event_at,
        campaign_performance.latest_attributed_order_event_at,

        campaign_performance.campaign_source_updated_at,
        campaign_performance.latest_web_event_source_updated_at,
        campaign_performance.latest_loaded_at

    from campaign_performance

    left join campaigns
        on campaign_performance.campaign_id = campaigns.campaign_id

)

select *
from final