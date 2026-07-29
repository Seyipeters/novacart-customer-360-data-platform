select
    web_event_source_record_id,
    event_id,
    session_id,
    event_timestamp,
    event_type,
    page_url,
    device_type,
    browser,
    traffic_source,
    source_record_arrived_at

from {{ ref('stg_web_analytics__web_events') }}

where trim(event_id) = ''
   or trim(session_id) = ''
   or trim(event_type) = ''
   or trim(page_url) = ''
   or trim(device_type) = ''
   or trim(browser) = ''
   or trim(traffic_source) = ''
   or source_record_arrived_at < event_timestamp