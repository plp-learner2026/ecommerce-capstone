CREATE FUNCTION place_order(p_address_id INT, p_product_ids INT[], p_quantities INT[])
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_customer INT := current_customer_id();
  v_order_id INT;
  v_count    INT := 0;
  r RECORD;
BEGIN
  IF v_customer IS NULL THEN
    RAISE EXCEPTION 'No customer set in this session';
  END IF;
  IF array_length(p_product_ids, 1) IS DISTINCT FROM array_length(p_quantities, 1) THEN
    RAISE EXCEPTION 'Product and quantity lists must have the same length';
  END IF;

  -- The composite foreign key rejects an address that belongs to another customer
  INSERT INTO orders (customer_id, address_id)
  VALUES (v_customer, p_address_id)
  RETURNING id INTO v_order_id;

  -- Lock product rows in id order, so two checkouts cannot deadlock each other
  FOR r IN
    SELECT p.id, p.price, i.qty
    FROM unnest(p_product_ids, p_quantities) AS i(pid, qty)
    JOIN products p ON p.id = i.pid
    ORDER BY p.id
    FOR UPDATE OF p
  LOOP
    UPDATE products SET stock = stock - r.qty
    WHERE id = r.id AND stock >= r.qty;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Insufficient stock for product %', r.id;
    END IF;

    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, r.id, r.qty, r.price);

    v_count := v_count + 1;
  END LOOP;

  IF v_count <> array_length(p_product_ids, 1) THEN
    RAISE EXCEPTION 'One or more products do not exist';
  END IF;

  RETURN v_order_id;  -- any error above rolls back the order, items and stock changes
END;
$$;

REVOKE ALL ON FUNCTION place_order(INT, INT[], INT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION place_order(INT, INT[], INT[]) TO capstone_app;