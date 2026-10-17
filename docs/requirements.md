\# Capstone: E-commerce Platform. Requirements Summary



\## Purpose

An online store where customers browse products, place orders and pay, and staff manage the catalog and fulfil orders.



\## Users and roles

\- \*\*Customer\*\*: browses products, manages a cart, places orders, sees only their own orders.

\- \*\*Staff\*\*: manages products and stock, updates order status.

\- \*\*Analyst\*\*: read-only access to reports.



\## Functional requirements

1\. Customers register and keep one or more addresses.

2\. Products belong to a category tree (for example Electronics > Computers > Laptops).

3\. Customers place orders containing one or more products; the price at purchase time is stored.

4\. Each order has one or more payments and a status (pending, paid, shipped, delivered, cancelled).

5\. Customers can review products they bought.

6\. Stock is reduced when an order is placed.



\## Analytical questions

1\. Top 10 products by revenue in the last 30 days.

2\. Monthly revenue per category.

3\. Customers with the most orders and their total spend.



\## Non-functional requirements

\- \*\*Performance\*\*: order history and reports respond within 100 ms on 100k+ orders.

\- \*\*Security\*\*: least-privilege roles, row-level security so customers see only their own rows, hashed passwords, audit log on orders and payments.

\- \*\*Reliability\*\*: daily logical backup and a tested restore.

\- \*\*NoSQL\*\*: shopping cart and product-page cache in Redis (details on Day 3).



\## Out of scope

Real payment gateways, shipping carriers, a front-end UI.

