-- LAST MILE DELIVERY ANALYTICS PROJECT

-- 1. Delivery Failure Hotspots by Pincode

WITH delivery_stats AS (
    SELECT 
        c.pincode,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN o.delivery_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
        SUM(CASE WHEN o.delivery_status IN ('Failed','RTO') THEN 1 ELSE 0 END) AS failed
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.pincode
)

SELECT 
    pincode,
    total_orders,
    delivered,
    failed,
    ROUND(delivered * 100.0 / total_orders, 2) AS success_rate
FROM delivery_stats
ORDER BY success_rate ASC
LIMIT 10;

-- 2. Rider Performance Ranking

SELECT
    r.rider_id,
    r.experience_years,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.delivery_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
    ROUND(
        SUM(CASE WHEN o.delivery_status = 'Delivered' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(o.order_id), 2
    ) AS success_rate,
    
    RANK() OVER (
        ORDER BY 
        SUM(CASE WHEN o.delivery_status = 'Delivered' THEN 1 ELSE 0 END) * 1.0 
        / COUNT(o.order_id) DESC
    ) AS rider_rank

FROM riders r
JOIN orders o ON r.rider_id = o.rider_id
GROUP BY r.rider_id, r.experience_years;

-- 3. Hub Delay Diagnostics

SELECT 
    h.hub_id,
    h.city,
    COUNT(o.order_id) AS total_orders,
    
    AVG(
        DATEDIFF(o.actual_delivery_time, o.promised_delivery_time)
    ) AS avg_delay_days,
    
    SUM(
        CASE WHEN o.actual_delivery_time > o.promised_delivery_time 
        THEN 1 ELSE 0 END
    ) AS late_deliveries

FROM hubs h
JOIN orders o ON h.hub_id = o.hub_id
GROUP BY h.hub_id, h.city
ORDER BY avg_delay_days DESC;

-- 4. Rider-Hub Failure Root Cause

SELECT 
    o.hub_id,
    o.rider_id,
    COUNT(*) total_orders,
    SUM(CASE WHEN delivery_status != 'Delivered' THEN 1 ELSE 0 END) failed,
    ROUND(
        SUM(CASE WHEN delivery_status != 'Delivered' THEN 1 ELSE 0 END) *100.0 / COUNT(*),
        2
    ) failure_rate

FROM orders o
GROUP BY o.hub_id, o.rider_id
HAVING failure_rate > 40
ORDER BY failure_rate DESC;


-- 5. High Risk Riders Detection

SELECT 
    o.hub_id,
    o.rider_id,
    COUNT(*) total_orders,
    SUM(CASE WHEN delivery_status != 'Delivered' THEN 1 ELSE 0 END) failed,
    ROUND(
        SUM(CASE WHEN delivery_status != 'Delivered' THEN 1 ELSE 0 END)*100.0 / COUNT(*),
        2
    ) failure_rate
FROM orders o
GROUP BY o.hub_id, o.rider_id
HAVING total_orders >= 5
ORDER BY failure_rate DESC;