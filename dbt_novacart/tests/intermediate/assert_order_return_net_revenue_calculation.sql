select
    order_id,
    total_order_item_net_amount,
    completed_refund_amount,
    net_item_revenue_after_refunds

from {{ ref('int_ecommerce__order_return_summary') }}

where abs(
    net_item_revenue_after_refunds
    - (
        total_order_item_net_amount
        - completed_refund_amount
      )
) >= 0.01