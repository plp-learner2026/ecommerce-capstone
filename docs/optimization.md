\# Day 4: Query Optimization Evidence



Data: 1,000 customers, 500 products, 20,000 orders, 60,000 order items (PostgreSQL 18.6).

Indexes were added through Flyway migration `V6\_\_query\_indexes.sql`.



\## Query 1

\*\*QUERY:\*\* Which orders contained product 42, and at what quantity and price?

```sql

SELECT o.id, o.ordered\_at, oi.quantity, oi.unit\_price

FROM order\_items oi JOIN orders o ON o.id = oi.order\_id

WHERE oi.product\_id = 42;

```

\*\*BEFORE PLAN (key lines):\*\*

```

Seq Scan on order\_items oi  (actual time=0.056..15.805 rows=120)

&#x20; Filter: (product\_id = 42)   Rows Removed by Filter: 59880

Seq Scan on orders o        (rows=20000)

Buffers: shared hit=531

Execution Time: 24.699 ms

```

\*\*CHANGE:\*\* `CREATE INDEX idx\_order\_items\_product ON order\_items (product\_id);` The filter on `product\_id` had no index, so every one of the 60,000 rows was read to find 120.

\*\*AFTER PLAN (key lines):\*\*

```

Bitmap Index Scan on idx\_order\_items\_product  (rows=120)

&#x20; Index Cond: (product\_id = 42)

Seq Scan on orders o        (rows=20000)

Buffers: shared hit=268 read=2

Execution Time: 5.930 ms

```

\*\*RESULT:\*\* 24.7 ms -> 5.9 ms (about 4x faster). Seq Scan -> Bitmap Index Scan on `order\_items`.

`orders` is still scanned sequentially: the join needs 120 of 20,000 rows, and the planner judged one pass cheaper than 120 index lookups.



\## Query 2

\*\*QUERY:\*\* How many orders were placed in the last 7 days?

```sql

SELECT count(\*) FROM orders WHERE ordered\_at >= now() - interval '7 days';

```

\*\*BEFORE PLAN (key lines):\*\*

```

Seq Scan on orders  (actual time=0.049..9.270 rows=743)

&#x20; Rows Removed by Filter: 19257

Buffers: shared hit=148

Execution Time: 9.409 ms

```

\*\*CHANGE:\*\* `CREATE INDEX idx\_orders\_ordered\_at ON orders (ordered\_at);` The date filter had no index, so all 20,000 rows were read.

\*\*AFTER PLAN (key lines):\*\*

```

Index Only Scan using idx\_orders\_ordered\_at  (rows=743)

&#x20; Heap Fetches: 6

Buffers: shared hit=2 read=3

Execution Time: 1.193 ms

```

\*\*RESULT:\*\* 9.4 ms -> 1.2 ms (about 8x faster). Seq Scan -> Index Only Scan. Buffers touched: 148 -> 5.



\## Notes

\- The data set is small, so absolute times are in milliseconds. The ratios and the plan changes are the evidence; the gap grows as the tables grow.

\- Timings vary from run to run. The first run after creating an index reads some pages from disk (`read=`), which is slightly slower than a warm cache.

