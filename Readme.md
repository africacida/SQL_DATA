This repository contains a production-ready MySQL schema for a modern e-commerce application.
It provides the foundation for managing users, products, categories, carts, orders, payments, inventory, coupons, and reviews with referential integrity and transactional safety.

🚀 Features

User Management: Customers, merchants, and admins with role-based access.

Product Catalog: Categories, products, images, and searchable product descriptions.

Inventory Control: Tracks stock and reserved quantities for accurate availability.

Shopping Cart: Persistent carts with guest session support.

Orders & Checkout: Orders, order items, discounts, taxes, and address support.

Payments: Supports multiple providers (Stripe, PayPal, Mobile Money, Manual).

Shipments: Carrier, tracking, and delivery lifecycle.

Reviews: Customer feedback with star ratings.

Coupons: Fixed or percentage discounts with validation rules.

Stored Procedure: Transactional place_order procedure (handles inventory checks, order creation, and payment placeholder).

🛠️ Setup
1. Create Database & Tables

Run the SQL schema in your MySQL/MariaDB environment:

mysql -u root -p < ecommerce_schema.sql


This will create a database named ecommerce with all tables, indexes, and relationships.

2. Load Sample Data

The schema comes with small seed data for:

Users (alice@example.com, bob@store.com, admin@ecom.com)

Categories (Electronics, Clothing, Home & Kitchen)

Products (Smartphone, T-Shirt, Frying Pan)

Inventory

⚙️ Usage
Running Queries

You can query the schema directly:

-- Search products
SELECT id, title, price FROM products WHERE MATCH(title, description) AGAINST('smartphone');

-- Get user orders
SELECT o.id, o.total, o.status
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'alice@example.com';

Place an Order (Stored Procedure)

The schema includes a transactional stored procedure place_order to simplify checkout.

Example usage:

SET @items_json = '[{"product_id":1,"quantity":2},{"product_id":3,"quantity":1}]';
CALL place_order(
  1,              -- user_id
  NULL,           -- shipping_address_id
  NULL,           -- billing_address_id
  'mobile_money', -- payment provider
  @items_json,
  @new_order_id,
  @err
);
SELECT @new_order_id, @err;

📂 Schema Overview

Users & Addresses → Authentication & shipping/billing.

Categories & Products → Product catalog & merchandising.

Inventory → Stock control & reserved items for pending orders.

Carts & Cart Items → Temporary shopping state for users & guests.

Orders & Order Items → Checkout flow with totals and status.

Payments → Tracks provider transactions and statuses.

Shipments → Delivery tracking & status updates.

Reviews → Ratings and feedback per product.

Coupons → Promotions and discount rules.

🔐 Security Notes

Store passwords as bcrypt/argon2 hashes (never plaintext).

Use parameterized queries in your application code to prevent SQL injection.

Enable SSL/TLS for database connections in production.

Regularly backup your database and manage migrations with a tool (Flyway, Liquibase, Prisma Migrate, Alembic, etc.).

🧩 Next Steps

Integrate with a backend framework (FastAPI, Express, NestJS, etc.)

Add role-based API access for merchants vs. customers.

Connect to real payment providers (Stripe, PayPal, MTN Mobile Money).

Build reporting & analytics (sales, inventory turnover, etc.).

👨🏽‍💻 Author: Your E-commerce Engineering Team
📅 Last Updated: 2025
