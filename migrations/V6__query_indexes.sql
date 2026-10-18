CREATE INDEX idx_order_items_product ON order_items (product_id);
CREATE INDEX idx_orders_ordered_at   ON orders (ordered_at);

ANALYZE order_items;
ANALYZE orders;