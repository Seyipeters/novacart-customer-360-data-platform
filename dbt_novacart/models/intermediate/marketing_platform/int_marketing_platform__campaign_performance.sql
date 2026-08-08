with campaign_engagement as (

    select *
    from {{ ref('int_marketing_platform__campaign_engagement_summary') }}

),

web_events as (

    select
        event_id,
        order_id,
        customer_id,
        campaign_id,
        event_timestamp

    from {{ ref('stg_web_analytics__web_events') }}

    where order_id is not null
      and campaign_id is not null

),

ranked_order_campaign_touches as (

    select
        event_id,
        order_id,
        customer_id,
        campaign_id,
        event_timestamp,

        row_number() over (
            partition by order_id
            order by
                event_timestamp desc,
                event_id desc
        ) as attribution_rank

    from web_events

),

attributed_orders as (

    select
        order_id,
        customer_id,
        campaign_id,
        event_timestamp as attributed_event_at

    from ranked_order_campaign_touches

    where attribution_rank = 1

),

order_payments as (

    select
        order_id,
        total_captured_amount,
        latest_payment_status,
        payment_reconciliation_status,
        currency_mismatch_flag

    from {{ ref('int_payment_gateway__order_payment_summary') }}

),

order_returns as (

    select
        order_id,
        completed_refund_amount,
        has_completed_return,
        order_return_status

    from {{ ref('int_ecommerce__order_return_summary') }}

),

attributed_order_financials as (

    select
        attributed.order_id,
        attributed.customer_id,
        attributed.campaign_id,
        attributed.attributed_event_at,

        coalesce(
            payments.total_captured_amount,
            0
        ) as captured_amount,

        coalesce(
            returns.completed_refund_amount,
            0
        ) as completed_refund_amount,

        coalesce(
            payments.total_captured_amount,
            0
        )
        -
        coalesce(
            returns.completed_refund_amount,
            0
        ) as net_revenue_after_refunds,

        payments.latest_payment_status,
        payments.payment_reconciliation_status,

        coalesce(
            payments.currency_mismatch_flag,
            false
        ) as currency_mismatch_flag,

        coalesce(
            returns.has_completed_return,
            false
        ) as has_completed_return,

        returns.order_return_status

    from attributed_orders as attributed

    left join order_payments as payments
        on attributed.order_id = payments.order_id

    left join order_returns as returns
        on attributed.order_id = returns.order_id

),

campaign_financial_summary as (

    select
        campaign_id,

        count(*) as attributed_order_count,

        count(distinct customer_id)
            as converted_customer_count,

        count_if(captured_amount > 0)
            as captured_payment_order_count,

        count_if(completed_refund_amount > 0)
            as refunded_order_count,

        count_if(currency_mismatch_flag)
            as currency_mismatch_order_count,

        sum(captured_amount)
            as total_captured_revenue,

        sum(completed_refund_amount)
            as total_completed_refund_amount,

        sum(net_revenue_after_refunds)
            as net_revenue_after_refunds,

        min(attributed_event_at)
            as first_attributed_order_event_at,

        max(attributed_event_at)
            as latest_attributed_order_event_at

    from attributed_order_financials

    group by campaign_id

),

final as (

    select
        campaign.campaign_id,
        campaign.campaign_name,
        campaign.campaign_channel,
        campaign.campaign_objective,
        campaign.campaign_status,
        campaign.target_segment,

        campaign.start_date,
        campaign.end_date,
        campaign.campaign_duration_days,

        campaign.budget_amount,
        campaign.currency,

        campaign.total_web_events,
        campaign.unique_customers_engaged,

        coalesce(
            financials.attributed_order_count,
            0
        ) as attributed_order_count,

        coalesce(
            financials.converted_customer_count,
            0
        ) as converted_customer_count,

        coalesce(
            financials.captured_payment_order_count,
            0
        ) as captured_payment_order_count,

        coalesce(
            financials.refunded_order_count,
            0
        ) as refunded_order_count,

        coalesce(
            financials.currency_mismatch_order_count,
            0
        ) as currency_mismatch_order_count,

        round(
            coalesce(financials.total_captured_revenue, 0),
            2
        ) as total_captured_revenue,

        round(
            coalesce(financials.total_completed_refund_amount, 0),
            2
        ) as total_completed_refund_amount,

        round(
            coalesce(financials.net_revenue_after_refunds, 0),
            2
        ) as net_revenue_after_refunds,

        round(
            100.0
            * coalesce(financials.converted_customer_count, 0)
            / nullif(campaign.unique_customers_engaged, 0),
            2
        ) as customer_conversion_rate_pct,

        round(
            campaign.budget_amount
            / nullif(financials.attributed_order_count, 0),
            2
        ) as cost_per_attributed_order,

        round(
            financials.net_revenue_after_refunds
            / nullif(financials.attributed_order_count, 0),
            2
        ) as average_net_order_value,

        round(
            financials.net_revenue_after_refunds
            / nullif(campaign.budget_amount, 0),
            2
        ) as return_on_ad_spend,

        round(
            100.0
            * financials.total_completed_refund_amount
            / nullif(financials.total_captured_revenue, 0),
            2
        ) as revenue_refund_rate_pct,

        financials.first_attributed_order_event_at,
        financials.latest_attributed_order_event_at,

        campaign.campaign_source_updated_at,
        campaign.latest_web_event_source_updated_at,
        campaign.latest_loaded_at

    from campaign_engagement as campaign

    left join campaign_financial_summary as financials
        on campaign.campaign_id = financials.campaign_id

)

select *
from final