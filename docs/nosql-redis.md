\# Day 3: NoSQL Layer (Redis)



\## What Redis is used for

1\. \*\*Shopping cart\*\*: one Redis hash per customer (`cart:<customer\_id>`), with product ids as fields and quantities as values.

2\. \*\*Product page cache\*\*: a short-lived copy of product data (`cache:product:<id>`) so popular pages don't hit PostgreSQL on every view.



\## Why Redis and not PostgreSQL for these

\- \*\*Carts are temporary.\*\* Most are abandoned. In PostgreSQL every abandoned cart would be rows that must be written, indexed, vacuumed and cleaned up by a scheduled job. In Redis, `EXPIRE` deletes an abandoned cart automatically (the cart below had a 1800-second countdown).

\- \*\*Carts change constantly.\*\* Adding, changing and removing items are single in-memory operations (`HSET`, `HINCRBY`, `HDEL`) instead of many small transactions with locks and write-ahead logging.

\- \*\*Caches need automatic expiry.\*\* `SET ... EX 300` stores a value that disappears by itself after 5 minutes, so stale data cannot live forever.

\- \*\*PostgreSQL keeps what must be permanent.\*\* Orders, payments and stock are financial records that need transactions, constraints and the audit trail, so they stay in PostgreSQL. When a customer checks out, the cart is read from Redis, written to `orders` and `order\_items` in one transaction, and then deleted from Redis.



\## Trade-off

Redis data lives in memory and can be lost if the server restarts without persistence. That is acceptable for a cart and a cache, but it would not be acceptable for orders.



\## Evidence (redis-cli session, Redis for Windows 5.0.14)

```

127.0.0.1:6379> HSET cart:5 product:1 2

(integer) 1

127.0.0.1:6379> HSET cart:5 product:7 1

(integer) 1

127.0.0.1:6379> HGETALL cart:5

1\) "product:1"

2\) "2"

3\) "product:7"

4\) "1"

127.0.0.1:6379> HINCRBY cart:5 product:1 1

(integer) 3

127.0.0.1:6379> HDEL cart:5 product:7

(integer) 1

127.0.0.1:6379> HGETALL cart:5

1\) "product:1"

2\) "3"

127.0.0.1:6379> EXPIRE cart:5 1800

(integer) 1

127.0.0.1:6379> TTL cart:5

(integer) 1782

127.0.0.1:6379> SET cache:product:1 "Product 1 - 120.50" EX 300

OK

127.0.0.1:6379> GET cache:product:1

"Product 1 - 120.50"

127.0.0.1:6379> TTL cache:product:1

(integer) 267

127.0.0.1:6379> DEL cart:5

(integer) 1

127.0.0.1:6379> EXISTS cart:5

(integer) 0

```

