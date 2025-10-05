-- Use a dedicated database
CREATE DATABASE IF NOT EXISTS ecommerce CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
USE ecommerce;

-- -----------------------------------------------------
-- USERS
-- -----------------------------------------------------
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(200),
  phone VARCHAR(30),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  role ENUM('customer','admin','merchant') NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ADDRESSES (user shipping/billing addresses)
-- -----------------------------------------------------
CREATE TABLE addresses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(50), -- e.g. "Home", "Office"
  recipient_name VARCHAR(200),
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100),
  region VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) DEFAULT 'Ghana',
  phone VARCHAR(30),
  is_default_shipping TINYINT(1) DEFAULT 0,
  is_default_billing TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- CATEGORIES
-- -----------------------------------------------------
CREATE TABLE categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id INT UNSIGNED NULL,
  name VARCHAR(150) NOT NULL,
  slug VARCHAR(180) NOT NULL UNIQUE,
  description TEXT,
  is_active TINYINT(1) DEFAULT 1,
  position INT DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PRODUCTS
-- -----------------------------------------------------
CREATE TABLE products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  merchant_id BIGINT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  sku VARCHAR(100) UNIQUE,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  short_description VARCHAR(512),
  description LONGTEXT,
  price DECIMAL(12,2) NOT NULL,
  compare_price DECIMAL(12,2) DEFAULT NULL,
  currency CHAR(3) DEFAULT 'GHS',
  weight_kg DECIMAL(8,3) DEFAULT 0.0,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_price (price),
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (merchant_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PRODUCT_IMAGES
-- -----------------------------------------------------
CREATE TABLE product_images (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  url VARCHAR(1000) NOT NULL,
  alt_text VARCHAR(255),
  position INT DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- INVENTORY (simple per-product inventory)
-- -----------------------------------------------------
CREATE TABLE inventory (
  product_id BIGINT UNSIGNED PRIMARY KEY,
  qty INT UNSIGNED NOT NULL DEFAULT 0,
  reserved INT UNSIGNED NOT NULL DEFAULT 0, -- held for pending orders
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- CARTS & CART_ITEMS (guest carts can be handled by token on frontend)
-- -----------------------------------------------------
CREATE TABLE carts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  session_token VARCHAR(255) NULL, -- for guests
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_user_session (user_id, session_token)
) ENGINE=InnoDB;

CREATE TABLE cart_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ORDERS & ORDER_ITEMS
-- -----------------------------------------------------
CREATE TABLE orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  user_id BIGINT UNSIGNED NULL,
  status ENUM('pending','paid','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(12,2) NOT NULL,
  shipping DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL,
  shipping_address_id BIGINT UNSIGNED NULL,
  billing_address_id BIGINT UNSIGNED NULL,
  placed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(id) ON DELETE SET NULL,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_title VARCHAR(255),
  sku VARCHAR(100),
  unit_price DECIMAL(12,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PAYMENTS
-- -----------------------------------------------------
CREATE TABLE payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  provider ENUM('stripe','paypal','mobile_money','manual') NOT NULL DEFAULT 'manual',
  provider_txn_id VARCHAR(255),
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) DEFAULT 'GHS',
  status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- SHIPMENTS
-- -----------------------------------------------------
CREATE TABLE shipments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  carrier VARCHAR(100),
  tracking_number VARCHAR(255),
  shipped_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  status ENUM('pending','in_transit','delivered','exception') DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PRODUCT REVIEWS
-- -----------------------------------------------------
CREATE TABLE reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  is_visible TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- COUPONS (simple)
-- -----------------------------------------------------
CREATE TABLE coupons (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  type ENUM('fixed','percent') NOT NULL DEFAULT 'percent',
  value DECIMAL(12,2) NOT NULL, -- if percent, 0-100
  usage_limit INT UNSIGNED DEFAULT NULL,
  used INT UNSIGNED DEFAULT 0,
  valid_from DATE DEFAULT NULL,
  valid_to DATE DEFAULT NULL,
  min_order_amount DECIMAL(12,2) DEFAULT 0.00,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- SIMPLE FULLTEXT for product search (MySQL 5.7+)
-- -----------------------------------------------------
ALTER TABLE products ADD FULLTEXT idx_ft_title_description (title, short_description, description);

-- -----------------------------------------------------
-- SAMPLE SEED DATA (small)
-- -----------------------------------------------------
INSERT INTO users (email, password_hash, full_name, phone, role)
VALUES
  ('alice@example.com','$2y$...hash...','Alice Example','+233201234567','customer'),
  ('bob@store.com','$2y$...hash...','Bob Merchant','+233205555111','merchant'),
  ('admin@ecom.com','$2y$...hash...','Platform Admin','+233000000000','admin');

INSERT INTO categories (name, slug) VALUES
  ('Electronics','electronics'),
  ('Clothing','clothing'),
  ('Home & Kitchen','home-kitchen');

INSERT INTO products (merchant_id, category_id, sku, title, slug, short_description, price)
VALUES
  (2, 1, 'SKU-1001', 'Smartphone Model X', 'smartphone-model-x', 'A powerful smartphone', 2499.00),
  (2, 2, 'SKU-2001', 'Cotton T-Shirt', 'cotton-tshirt', 'Comfortable everyday tee', 79.99),
  (2, 3, 'SKU-3001', 'Nonstick Frying Pan', 'nonstick-frying-pan', '12-inch durable pan', 149.50);

INSERT INTO inventory (product_id, qty) VALUES
  (1, 50),
  (2, 200),
  (3, 75);

-- -----------------------------------------------------
-- TRANSACTIONAL STORED PROCEDURE: PLACE ORDER
-- Simplified example: checks inventory, creates order and items, deducts inventory, creates payment record.
-- NOTE: Adapt error handling/payment integration & security for production.
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS place_order;
DELIMITER $$
CREATE PROCEDURE place_order (
  IN p_user_id BIGINT,
  IN p_shipping_address_id BIGINT,
  IN p_billing_address_id BIGINT,
  IN p_payment_provider VARCHAR(32),
  IN p_items JSON, -- JSON array: [{"product_id":1,"quantity":2},{"product_id":2,"quantity":1}]
  OUT p_order_id BIGINT,
  OUT p_error_message VARCHAR(4000)
)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE prod_id BIGINT;
  DECLARE qty INT;
  DECLARE unit_price DECIMAL(12,2);
  DECLARE subtotal DECIMAL(12,2) DEFAULT 0.00;
  DECLARE line_total DECIMAL(12,2);
  DECLARE cur_index INT DEFAULT 0;
  DECLARE items_count INT DEFAULT JSON_LENGTH(p_items);
  DECLARE tmp_total DECIMAL(12,2) DEFAULT 0.00;

  SET p_order_id = NULL;
  SET p_error_message = NULL;

  START TRANSACTION;

  -- iterate items (simple loop)
  label_loop: WHILE cur_index < items_count DO
    SET prod_id = JSON_EXTRACT(p_items, CONCAT('$[', cur_index, '].product_id'));
    SET qty = JSON_EXTRACT(p_items, CONCAT('$[', cur_index, '].quantity'));

    -- get product price and inventory
    SELECT price INTO unit_price FROM products WHERE id = prod_id FOR UPDATE;
    SELECT qty, reserved INTO @inv_qty, @inv_reserved FROM inventory WHERE product_id = prod_id FOR UPDATE;

    IF @inv_qty IS NULL THEN
      SET p_error_message = CONCAT('Product not found in inventory: ', prod_id);
      ROLLBACK;
      LEAVE label_loop;
    END IF;

    IF @inv_qty - @inv_reserved < qty THEN
      SET p_error_message = CONCAT('Insufficient inventory for product: ', prod_id);
      ROLLBACK;
      LEAVE label_loop;
    END IF;

    SET line_total = unit_price * qty;
    SET subtotal = subtotal + line_total;

    -- reserve inventory (increase reserved)
    UPDATE inventory SET reserved = reserved + qty WHERE product_id = prod_id;

    SET cur_index = cur_index + 1;
  END WHILE;

  IF p_error_message IS NOT NULL THEN
    -- error already set and rolled back
    RETURN;
  END IF;

  -- create order
  INSERT INTO orders (order_number, user_id, status, subtotal, shipping, tax, discount, total, shipping_address_id, billing_address_id, placed_at)
  VALUES (
    CONCAT('ORD-', DATE_FORMAT(NOW(),'%Y%m%d'), '-', LPAD(FLOOR(RAND()*99999),5,'0')),
    p_user_id,
    'pending',
    subtotal,
    0.00,
    0.00,
    0.00,
    subtotal, -- total = subtotal + shipping + tax - discount
    p_shipping_address_id,
    p_billing_address_id,
    NOW()
  );

  SET p_order_id = LAST_INSERT_ID();

  -- insert order items and deduct inventory
  SET cur_index = 0;
  WHILE cur_index < items_count DO
    SET prod_id = JSON_EXTRACT(p_items, CONCAT('$[', cur_index, '].product_id'));
    SET qty = JSON_EXTRACT(p_items, CONCAT('$[', cur_index, '].quantity'));

    SELECT title, sku, price INTO @prod_title, @prod_sku, @prod_price FROM products WHERE id = prod_id;

    INSERT INTO order_items (order_id, product_id, product_title, sku, unit_price, quantity, line_total)
    VALUES (p_order_id, prod_id, @prod_title, @prod_sku, @prod_price, qty, @prod_price * qty);

    -- update inventory: subtract qty and reserved
    UPDATE inventory SET qty = qty - qty, reserved = reserved - qty WHERE product_id = prod_id;

    SET cur_index = cur_index + 1;
  END WHILE;

  -- create payment placeholder (status pending) - integrate with provider in app layer
  INSERT INTO payments (order_id, provider, amount, currency, status, metadata)
  VALUES (p_order_id, p_payment_provider, subtotal, 'GHS', 'pending', JSON_OBJECT('note','created by place_order proc'));

  COMMIT;

END $$
DELIMITER ;

-- -----------------------------------------------------
-- USAGE EXAMPLE of the stored procedure (call from app/backend)
-- -----------------------------------------------------
-- Example JSON payload (2 items)
-- SET @items_json = '[{"product_id":1,"quantity":2},{"product_id":3,"quantity":1}]';
-- CALL place_order(1, NULL, NULL, 'mobile_money', @items_json, @new_order_id, @err);
-- SELECT @new_order_id, @err;

-- -----------------------------------------------------
-- SUGGESTED INDEXES (add more based on query patterns)
-- -----------------------------------------------------
CREATE INDEX idx_products_merchant ON products (merchant_id);
CREATE INDEX idx_orders_user ON orders (user_id);
CREATE INDEX idx_payments_order ON payments (order_id);
CREATE INDEX idx_inventory_qty ON inventory (qty);

-- End of schema

