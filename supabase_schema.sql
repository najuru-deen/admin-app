-- =============================================================
-- Veetla Visesanga (VV) — Supabase / PostgreSQL Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- =============================================================

-- Users (app customers)
CREATE TABLE IF NOT EXISTS vv_users (
  id         BIGSERIAL PRIMARY KEY,
  mobile     TEXT UNIQUE NOT NULL,
  city       TEXT,
  otp        TEXT,
  otp_expires BIGINT,
  created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- Cities
CREATE TABLE IF NOT EXISTS vv_cities (
  id     BIGSERIAL PRIMARY KEY,
  name   TEXT NOT NULL,
  active INTEGER DEFAULT 1
);

-- Regions (sub-areas within cities)
CREATE TABLE IF NOT EXISTS vv_regions (
  id      BIGSERIAL PRIMARY KEY,
  city_id BIGINT REFERENCES vv_cities(id),
  name    TEXT NOT NULL,
  areas   TEXT,
  active  INTEGER DEFAULT 1
);

-- Categories
CREATE TABLE IF NOT EXISTS vv_categories (
  id     BIGSERIAL PRIMARY KEY,
  name   TEXT NOT NULL,
  icon   TEXT,
  active INTEGER DEFAULT 1
);

-- Vendors
CREATE TABLE IF NOT EXISTS vv_vendors (
  id                  BIGSERIAL PRIMARY KEY,
  name                TEXT NOT NULL,
  full_address        TEXT,
  mobile              TEXT NOT NULL,
  category_id         BIGINT REFERENCES vv_categories(id),
  city_id             BIGINT REFERENCES vv_cities(id),
  region_id           BIGINT REFERENCES vv_regions(id),
  membership_tier     TEXT DEFAULT 'basic',
  is_verified         INTEGER DEFAULT 0,
  is_trusted          INTEGER DEFAULT 0,
  is_trending         INTEGER DEFAULT 0,
  description         TEXT,
  amount              TEXT,
  rating              REAL DEFAULT 0,
  rating_count        INTEGER DEFAULT 0,
  whatsapp            TEXT,
  latitude            REAL,
  longitude           REAL,
  status              TEXT DEFAULT 'pending',
  subscription_expires BIGINT,
  created_at          BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- Vendor Media
CREATE TABLE IF NOT EXISTS vv_vendor_media (
  id         BIGSERIAL PRIMARY KEY,
  vendor_id  BIGINT REFERENCES vv_vendors(id),
  type       TEXT,
  url        TEXT,
  created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- Leads (customer inquiries)
CREATE TABLE IF NOT EXISTS vv_leads (
  id          BIGSERIAL PRIMARY KEY,
  vendor_id   BIGINT REFERENCES vv_vendors(id),
  user_mobile TEXT,
  type        TEXT,
  created_at  BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- Memberships / Subscriptions
CREATE TABLE IF NOT EXISTS vv_memberships (
  id             BIGSERIAL PRIMARY KEY,
  vendor_id      BIGINT REFERENCES vv_vendors(id),
  tier           TEXT,
  amount         INTEGER,
  payment_status TEXT DEFAULT 'pending',
  payment_ref    TEXT,
  created_at     BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT,
  expires_at     BIGINT
);

-- Admin Users
CREATE TABLE IF NOT EXISTS vv_admin_users (
  id         BIGSERIAL PRIMARY KEY,
  username   TEXT UNIQUE NOT NULL,
  password   TEXT NOT NULL,
  created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- Admin Audit Log
CREATE TABLE IF NOT EXISTS vv_admin_audit_log (
  id             BIGSERIAL PRIMARY KEY,
  admin_username TEXT NOT NULL,
  action         TEXT NOT NULL,
  entity_type    TEXT,
  entity_id      TEXT,
  details        TEXT,
  ip_address     TEXT,
  created_at     BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

-- =============================================================
-- Indexes for common queries
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_vv_vendors_status        ON vv_vendors(status);
CREATE INDEX IF NOT EXISTS idx_vv_vendors_city_id       ON vv_vendors(city_id);
CREATE INDEX IF NOT EXISTS idx_vv_vendors_category_id   ON vv_vendors(category_id);
CREATE INDEX IF NOT EXISTS idx_vv_vendors_created_at    ON vv_vendors(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vv_leads_vendor_id       ON vv_leads(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vv_leads_created_at      ON vv_leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vv_memberships_vendor_id ON vv_memberships(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vv_audit_created_at      ON vv_admin_audit_log(created_at DESC);

-- =============================================================
-- Seed data
-- =============================================================

INSERT INTO vv_admin_users (username, password)
VALUES ('admin', 'admin123')
ON CONFLICT (username) DO NOTHING;

INSERT INTO vv_cities (name, active) VALUES
  ('Chennai', 1), ('Coimbatore', 1), ('Tiruchirapalli', 1),
  ('Madurai', 1), ('Tirunelveli', 1)
ON CONFLICT (name) DO NOTHING;

INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Madurai West', 'Arappalayam,Kochadai,Ponmeni,Kalavasal,Nagamalai Pudukottai' FROM vv_cities WHERE name = 'Madurai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Madurai East', 'Pasumalai,Tallakulam,Thirunagar,Sellur,Gomathipuram' FROM vv_cities WHERE name = 'Madurai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Madurai North', 'Simmakkal,KK Nagar,Anna Nagar,Vilangudi,Othakadai' FROM vv_cities WHERE name = 'Madurai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Madurai South', 'Vandiyur,Alagarkovil,Teppakulam,Goripalayam' FROM vv_cities WHERE name = 'Madurai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'North Chennai', 'Perambur,Kolathur,Tondiarpet,Royapuram,Tiruvottiyur' FROM vv_cities WHERE name = 'Chennai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'South Chennai', 'Adyar,Velachery,Tambaram,Pallavaram,Chromepet' FROM vv_cities WHERE name = 'Chennai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Central Chennai', 'T Nagar,Nungambakkam,Egmore,Mylapore,Alwarpet' FROM vv_cities WHERE name = 'Chennai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;
INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'West Chennai', 'Porur,Valasaravakkam,Ambattur,Poonamallee,Koyambedu' FROM vv_cities WHERE name = 'Chennai' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO vv_categories (name, icon) VALUES
  ('Mandapam','🏛️'), ('Catering','🍽️'), ('Decorators','🎨'),
  ('Makeup Artist','💄'), ('Photography','📷'), ('Invitation Cards','💌'),
  ('Event Management','🎪'), ('Music Events','🎵'), ('Rentals','🛒'),
  ('Water Bottle Suppliers','💧'), ('Flowers & Garland','🌸'),
  ('Service Apartments','🏠'), ('Blouse & Aari Work','🧵'),
  ('Travels','🚗'), ('Flex Printing','🖨️'), ('Crackers','🎆'),
  ('Furniture','🪑'), ('Home Appliances','🔌'), ('Sweets','🍮'),
  ('Utensils','🥄')
ON CONFLICT (name) DO NOTHING;

-- =============================================================
-- Disable Row Level Security (required for anon key access)
-- Run these after creating the tables above
-- =============================================================
ALTER TABLE vv_users          DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_cities         DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_regions        DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_categories     DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_vendors        DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_vendor_media   DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_leads          DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_memberships    DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_admin_users    DISABLE ROW LEVEL SECURITY;
ALTER TABLE vv_admin_audit_log DISABLE ROW LEVEL SECURITY;

-- =============================================================
-- DEMO DATA SUPPORT — Schema additions
-- =============================================================

-- is_demo flag on vendors (1 = sample/demo record)
ALTER TABLE vv_vendors    ADD COLUMN IF NOT EXISTS is_demo  INTEGER DEFAULT 0;
ALTER TABLE vv_categories ADD COLUMN IF NOT EXISTS name_ta  TEXT;

CREATE INDEX IF NOT EXISTS idx_vv_vendors_is_demo ON vv_vendors(is_demo);

-- Global app settings (key/value store)
CREATE TABLE IF NOT EXISTS vv_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL DEFAULT '',
  label      TEXT,
  updated_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);
ALTER TABLE vv_settings DISABLE ROW LEVEL SECURITY;

INSERT INTO vv_settings (key, value, label)
VALUES ('demo_data_enabled', '0', 'Show demo/sample vendor data in the mobile app')
ON CONFLICT (key) DO NOTHING;

-- =============================================================
-- Update category icons & add Tamil names (match mobile app)
-- =============================================================
UPDATE vv_categories SET icon = '🌸' WHERE name = 'Decorators';
UPDATE vv_categories SET icon = '🪑' WHERE name = 'Rentals';
UPDATE vv_categories SET icon = '🌺' WHERE name = 'Flowers & Garland';
UPDATE vv_categories SET icon = '🪡' WHERE name = 'Blouse & Aari Work';
UPDATE vv_categories SET icon = '🚌' WHERE name = 'Travels';
UPDATE vv_categories SET icon = '🪞' WHERE name = 'Furniture';
UPDATE vv_categories SET icon = '🥘' WHERE name = 'Utensils';

UPDATE vv_categories SET name_ta = CASE name
  WHEN 'Mandapam'               THEN 'மண்டபம்'
  WHEN 'Catering'               THEN 'உணவு சேவை'
  WHEN 'Decorators'             THEN 'அலங்காரம்'
  WHEN 'Makeup Artist'          THEN 'அழகு கலை'
  WHEN 'Photography'            THEN 'புகைப்படம்'
  WHEN 'Invitation Cards'       THEN 'அழைப்பிதழ்'
  WHEN 'Event Management'       THEN 'நிகழ்வு மேலாண்மை'
  WHEN 'Music Events'           THEN 'இசை நிகழ்வு'
  WHEN 'Rentals'                THEN 'வாடகை'
  WHEN 'Water Bottle Suppliers' THEN 'நீர் வழங்குனர்'
  WHEN 'Flowers & Garland'      THEN 'பூ & மாலை'
  WHEN 'Service Apartments'     THEN 'சேவை இல்லம்'
  WHEN 'Blouse & Aari Work'     THEN 'ரவிக்கை & ஆரி'
  WHEN 'Travels'                THEN 'பயணம்'
  WHEN 'Flex Printing'          THEN 'அச்சிடுதல்'
  WHEN 'Crackers'               THEN 'பட்டாசு'
  WHEN 'Furniture'              THEN 'தளபாடம்'
  WHEN 'Home Appliances'        THEN 'உபகரணங்கள்'
  WHEN 'Sweets'                 THEN 'இனிப்புகள்'
  WHEN 'Utensils'               THEN 'பாத்திரம்'
END;

-- =============================================================
-- Align region names to mobile app & add missing city regions
-- =============================================================
UPDATE vv_regions SET name = 'Chennai Central' WHERE name = 'Central Chennai';
UPDATE vv_regions SET name = 'Chennai South'   WHERE name = 'South Chennai';
UPDATE vv_regions SET name = 'Chennai North'   WHERE name = 'North Chennai';
UPDATE vv_regions SET name = 'Chennai West'    WHERE name = 'West Chennai';

INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Coimbatore Central', 'RS Puram,Gandhipuram,Peelamedu'
FROM vv_cities WHERE name = 'Coimbatore' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Coimbatore West', 'Saravanampatti,Singanallur'
FROM vv_cities WHERE name = 'Coimbatore' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Trichy Central', 'Srirangam,Thiruverumbur,Ariyamangalam'
FROM vv_cities WHERE name = 'Tiruchirapalli' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO vv_regions (city_id, name, areas)
SELECT id, 'Tirunelveli Central', 'Palayamkottai,Melapalayam,Nanguneri'
FROM vv_cities WHERE name = 'Tirunelveli' LIMIT 1
ON CONFLICT (city_id, name) DO NOTHING;

-- =============================================================
-- Demo vendor seed data (104 vendors from mobile app mockData)
-- All have status='approved', is_demo=1
-- Uses subqueries to resolve category/city/region IDs by name
-- =============================================================

-- Helper macro (reused in each INSERT):
-- category_id  → (SELECT id FROM vv_categories WHERE name='...' LIMIT 1)
-- city_id      → (SELECT id FROM vv_cities WHERE name='...' LIMIT 1)
-- region_id    → (SELECT id FROM vv_regions WHERE name='...' LIMIT 1)

-- ── MANDAPAM ──────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'MRC Mahal','70 Feet Road, Ellis Nagar, Madurai','9876543210','9876543210',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'MRC Mahal is one of the most prestigious marriage halls in Madurai. Built in 2005, hosted over 5,000 events. Grand entrance, LED pillars, landscaped garden, centralized AC, premium sound system.','₹2,00,000',4.8,124,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876543210' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sri Murugan Kalyana Mandapam','Anna Nagar Main Road, Madurai','9865432107','9865432107',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Sri Murugan Kalyana Mandapam offers a divine setting for your wedding. Established 1998, renowned for religious ambiance and traditional architecture. Capacity 500 guests.','₹1,50,000',4.5,89,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865432107' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Royal Celebration Hall','Bypass Road, Anna Nagar, Madurai','9843210987','9843210987',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'gold',1,1,0,'Modern banquet facility with designer chandeliers, imported marble flooring, and professional kitchen. Capacity 600 guests.','₹1,75,000',4.6,67,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843210987' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Lakshmi Gardens','Thiruppalai Road, Madurai East','9845671230','9845671230',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Beautiful outdoor wedding venue with lush green surroundings. Perfect for open-air ceremonies. Capacity 300.','₹80,000',4.2,45,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9845671230' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vinayagar Mini Hall','KK Nagar West, Madurai North','9867543210','9867543210',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'silver',1,0,0,'Budget-friendly mini hall perfect for intimate wedding ceremonies and small family events. Capacity 150.','₹45,000',4.0,32,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9867543210' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Arul Jothi Conference Hall','Tallakulam, Madurai South','9854321076',NULL,
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'silver',1,0,0,'Multipurpose conference hall suitable for small weddings, receptions, and corporate events. Capacity 200.','₹60,000',3.9,28,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9854321076' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Ponmeni Community Hall','Ponmeni Main Street, Madurai West','9823456780',NULL,
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.8,12,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823456780' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Thiruppalai Kalyana Hall','Thiruppalai East, Madurai','9812345670',NULL,
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'basic',0,0,0,'',NULL,3.5,7,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812345670' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Thirumangalam Event Hall','Thirumangalam Road, Madurai','9801234560',NULL,
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'basic',0,0,0,'',NULL,3.6,9,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801234560' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Grand Palace Kalyana Mahal','Anna Salai, T Nagar, Chennai','9876500001','9876500001',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Chennai''s premier wedding venue in T Nagar. Capacity 1500 guests, state-of-the-art audio-visual equipment, 15 rooms, 300-car parking.','₹3,50,000',4.9,210,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500001' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Adyar Mahal','Lattice Bridge Road, Adyar, Chennai','9865400002','9865400002',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai South' LIMIT 1),
  'gold',1,1,0,'Landmark wedding venue in South Chennai offering elegant interiors and professional event management. Capacity 800 guests.','₹2,20,000',4.7,98,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400002' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kovai Marriage Hall','Avinashi Road, Peelamedu, Coimbatore','9843400003','9843400003',
  (SELECT id FROM vv_categories WHERE name='Mandapam' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Coimbatore' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Coimbatore Central' LIMIT 1),
  'gold',1,1,0,'Blend of traditional and modern aesthetics in the heart of Coimbatore. Capacity 550 guests, 6 rooms, 100-car parking.','₹1,60,000',4.4,74,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400003' AND is_demo=1);

-- ── CATERING ──────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Annapoorna Catering Services','KK Nagar, Madurai','9876012345','9876012345',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Authentic Tamil Nadu cuisine for over 20 years. 50+ dishes, 50 expert chefs. Serves 200–5000 plates. Both veg and non-veg.','₹450 per plate',4.9,213,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876012345' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Saravana Bhavan Catering','Anna Nagar, Madurai East','9876098765','9876098765',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Legendary Saravana Bhavan taste at your wedding. Authentic South Indian dishes. Pure veg. 300–8000 plates.','₹420 per plate',4.8,178,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876098765' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Chettinad Catering','Arappalayam, Madurai West','9865432198','9865432198',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Authentic Chettinad cuisine specialists. Signature dishes: Chettinad Chicken, Kavuni Arisi, kozhi kuzhambu. 150–3000 plates.','₹380 per plate',4.6,134,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865432198' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Saraswathi Catering','KK Nagar, Madurai North','9845678901','9845678901',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Pure vegetarian, authentic South Indian flavors. Ideal for brahmin weddings. No onion/garlic options. 100–2000 plates.','₹350 per plate',4.5,98,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9845678901' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Hotel Pandian Catering','Tallakulam, Madurai South','9834567890','9834567890',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,1,0,'Premium quality food with excellent presentation. Handles mini weddings to 4000+ guest events with equal dedication.','₹400 per plate',4.4,87,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834567890' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Catering','KK Nagar West, Madurai','9834512367','9834512367',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Budget-friendly catering with quality Tamil cuisine for all occasions.','₹280 per plate',4.1,34,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834512367' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Karpagam Catering','Ponmeni, Madurai West','9823456001','9823456001',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Affordable and hygienic catering for medium-sized weddings. Traditional Tamil menu.','₹260 per plate',4.0,26,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823456001' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Senthil Catering','Thirumangalam, Madurai North','9812345001','9812345001',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'silver',1,0,0,'Home-style cooking with fresh ingredients for intimate wedding celebrations.','₹300 per plate',4.2,41,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812345001' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Lakshmi Food Suppliers','Arappalayam, Madurai','9823456123',NULL,
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.5,8,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823456123' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Deepam Catering','Anaiyur, Madurai South','9801234001',NULL,
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'basic',0,0,0,'',NULL,3.7,11,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801234001' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Chennai Grand Catering','T Nagar, Chennai','9876500101','9876500101',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Chennai''s most trusted wedding caterer. Tamil Brahmin, Mudaliar, and Nadar cuisines. 500–10000 plates.','₹500 per plate',4.9,245,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500101' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kongu Catering','Gandhipuram, Coimbatore','9843400101','9843400101',
  (SELECT id FROM vv_categories WHERE name='Catering' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Coimbatore' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Coimbatore Central' LIMIT 1),
  'gold',1,1,0,'Traditional Kongu Nadu cuisine. Signature dishes include Nattu Kozhi Kulambu and traditional sweets. 200–3000 plates.','₹360 per plate',4.5,92,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400101' AND is_demo=1);

-- ── DECORATORS ────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Dream Decors','Bypass Road, Madurai','9876500111','9876500111',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'8 years expertise, 1500+ events. Stunning stage setups, floral arrangements, lighting effects, and theme decorations.','₹1,20,000 onwards',4.8,95,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500111' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Royal Floral Designs','Anna Nagar, Madurai East','9865400222','9865400222',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Fresh flower mandap, LED lighting, draping, and photo booth setups. Blends tradition with modern elegance.','₹1,50,000 onwards',4.9,112,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400222' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Elegant Events Decor','KK Nagar, Madurai North','9843400333','9843400333',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Contemporary wedding decorations with imported flowers and premium fabrics.','₹75,000 onwards',4.6,78,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400333' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vivah Decorations','Tallakulam, Madurai South','9834400444','9834400444',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,1,0,'Budget-friendly yet beautiful decoration packages. Traditional and fusion themes for big and small weddings.','₹60,000 onwards',4.4,54,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834400444' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sakthi Flower Decor','Kochadai, Madurai West','9823400555','9823400555',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Affordable flower decoration using fresh marigolds, roses, and jasmine.','₹35,000 onwards',4.1,38,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823400555' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kavitha Decoration Works','Iyer Bungalow, Madurai East','9812400666','9812400666',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Traditional stage and mandap decoration for all budgets. Available for outstation events.','₹30,000 onwards',4.0,27,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812400666' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Decors','Othakadai, Madurai North','9801400777',NULL,
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'basic',0,0,0,'',NULL,3.7,14,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801400777' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Chennai Floral Paradise','Nungambakkam, Chennai','9876500301','9876500301',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Chennai''s leading wedding decoration company. Luxury rose and orchid mandap setups. Destination wedding décor available.','₹2,00,000 onwards',4.9,187,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500301' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kovai Decorators','RS Puram, Coimbatore','9843400301','9843400301',
  (SELECT id FROM vv_categories WHERE name='Decorators' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Coimbatore' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Coimbatore Central' LIMIT 1),
  'gold',1,1,0,'Creative and artistic wedding decoration in Coimbatore. Specialised in both traditional and contemporary styles.','₹80,000 onwards',4.5,65,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400301' AND is_demo=1);

-- ── MAKEUP ARTIST ─────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Glam Studio by Kavitha','KK Nagar, Madurai','9876511222','9876511222',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Madurai''s most sought-after bridal studio. 12 years, 5 artists. HD bridal makeup, silk saree draping, mehendi. Premium brands: MAC, NARS, Huda Beauty.','₹25,000 onwards',4.9,143,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876511222' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Bridal Bloom Studio','Anna Nagar, Madurai East','9865411333','9865411333',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Airbrush makeup specialists. Look radiant from ceremony to reception. 4 trained artists.','₹22,000 onwards',4.8,119,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865411333' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Royal Touch Makeup','Arappalayam, Madurai West','9843411444','9843411444',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Bride and groom makeovers. Signature look combines traditional Tamil bridal with modern beauty trends.','₹15,000 onwards',4.6,87,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411444' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Priya Makeover Studio','KK Nagar North, Madurai','9834411555','9834411555',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Affordable bridal makeup packages without compromising quality. Home service available across Madurai.','₹12,000 onwards',4.4,62,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834411555' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Rani Beauty Parlour','Palanganatham, Madurai South','9823411666','9823411666',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'silver',1,0,0,'Traditional bridal makeup with a modern touch. Experienced in Hindu and Christian wedding styles.','₹8,000 onwards',4.1,44,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411666' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sugandha Bridal Makeup','Thiruppalai, Madurai East','9812411777','9812411777',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Budget-friendly bridal makeup. Mehendi and hair styling also available.','₹7,000 onwards',4.0,31,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812411777' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vasantha Beauty Care','Ponmeni, Madurai West','9801411888',NULL,
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.8,16,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411888' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Chennai Bridal Couture','T Nagar, Chennai','9876500401','9876500401',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Celebrity makeup artist Divya and team. 7 artists using luxury international brands. Chennai''s go-to bridal studio.','₹40,000 onwards',4.9,231,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500401' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Meera Makeup Studio','Gandhipuram, Coimbatore','9843400401','9843400401',
  (SELECT id FROM vv_categories WHERE name='Makeup Artist' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Coimbatore' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Coimbatore Central' LIMIT 1),
  'gold',1,1,0,'Flawless bridal finishes. Specialising in HD and airbrush makeup techniques.','₹18,000 onwards',4.5,73,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400401' AND is_demo=1);

-- ── PHOTOGRAPHY ───────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Pixel Perfect Studios','West Masi Street, Madurai','9876543099','9876543099',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Madurai''s #1 wedding photography studio. 10+ years, 6 photographers, 4 videographers. Canon EOS R5 & Sony A7. Cinematic films, drone, same-day edits.','₹75,000 onwards',4.9,186,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876543099' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'CineWeddings Madurai','Anna Nagar, Madurai East','9865400502','9865400502',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Emotional storytelling through stunning visuals. Nationally recognised cinematic wedding films. Covers mehendi to reception.','₹65,000 onwards',4.8,152,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400502' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Madurai Moments Photography','West Masi St, Madurai West','9843400503','9843400503',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Candid wedding photography specialists capturing real emotions and unscripted moments.','₹45,000 onwards',4.7,112,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400503' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Snapshot Creations','Othakadai, Madurai North','9834400504','9834400504',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Artistic wedding albums and cinematic highlight reels. Drone coverage available.','₹40,000 onwards',4.5,84,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834400504' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kalaivani Photography','Anaiyur, Madurai South','9823400505','9823400505',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,1,0,'Budget-friendly wedding photography with professional quality. Specialised in documenting traditional Tamil wedding rituals.','₹35,000 onwards',4.3,67,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823400505' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Rajan Photo Works','Thiruppalai, Madurai East','9812400506','9812400506',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Traditional and digital photography. 15+ years capturing Tamil weddings.','₹20,000 onwards',4.1,43,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812400506' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Suresh Video Studio','Kochadai, Madurai West','9801400507','9801400507',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Photography and videography package at affordable rate. Serving Madurai for over 10 years.','₹18,000 onwards',4.0,29,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801400507' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kumar Photography','Thirumangalam, Madurai North','9789400508',NULL,
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'basic',0,0,0,'',NULL,3.6,12,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9789400508' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Frame of Life Studios','Nungambakkam, Chennai','9876500501','9876500501',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Chennai''s most awarded wedding photography studio. 14 years, 3000+ weddings. Drone, aerial, destination wedding coverage.','₹1,00,000 onwards',4.9,298,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500501' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Coimbatore Click Studio','Peelamedu, Coimbatore','9843400501','9843400501',
  (SELECT id FROM vv_categories WHERE name='Photography' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Coimbatore' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Coimbatore Central' LIMIT 1),
  'gold',1,1,0,'Professional wedding photography and videography. Candid and traditional coverage with same-week delivery.','₹50,000 onwards',4.6,91,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400501' AND is_demo=1);

-- ── INVITATION CARDS ──────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Royal Wedding Cards','North Veli Street, Madurai','9876544555','9876544555',
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Premium wedding invitation design and printing. 300+ templates, digital WhatsApp invitations, box invitations, and silk-finish traditional cards.','₹8 per card',4.8,201,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876544555' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Elegant Invites Studio','Anna Nagar, Madurai East','9865400602','9865400602',
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,0,'Premium laser-cut and foil-embossed cards. Save-the-date, wedding menus, thank-you cards. Custom box packaging.','₹12 per card',4.7,165,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400602' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Kalai Print House','North Masi Street, Madurai','9843400603','9843400603',
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Traditional and modern cards with premium paper and vibrant colours. Same-day design approval available.','₹6 per card',4.5,98,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400603' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Creative Card Studio','KK Nagar, Madurai North','9834400604','9834400604',
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,0,0,'Creative and affordable wedding invitations with fast turnaround. Minimum order 200 cards.','₹5 per card',4.3,76,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834400604' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vimal Cards','Palanganatham, Madurai South','9823400605','9823400605',
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'silver',1,0,0,'Budget invitations. 50+ templates. Free WhatsApp digital cards with print orders.','₹4 per card',4.0,42,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823400605' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Printing Press','Arappalayam, Madurai','9801400606',NULL,
  (SELECT id FROM vv_categories WHERE name='Invitation Cards' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.5,10,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801400606' AND is_demo=1);

-- ── MUSIC EVENTS ──────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sakthi Band & Orchestra','Simmakkal, Madurai','9876522333','9876522333',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'25 years of musical excellence. Traditional Nadaswaram & Thavil, full orchestra, DJ, Kettimelam. 15 trained musicians.','₹35,000 onwards',4.7,178,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876522333' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Nada Vinodha Musical Troupe','Anna Nagar, Madurai East','9865400802','9865400802',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'One of the oldest and most respected troupes in South Tamil Nadu. Classical Carnatic, Nadaswaram, Thavil, and modern orchestra. 20 musicians.','₹40,000 onwards',4.8,143,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400802' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Beat Box DJ Events','KK Nagar, Madurai North','9843400803','9843400803',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Premier DJ events. Latest JBL sound systems, LED lighting. Tamil, Bollywood, and English music mixes.','₹20,000 onwards',4.5,87,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843400803' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vel DJ Events','Tallakulam, Madurai South','9834400804','9834400804',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,0,0,'Modern DJ and sound system services for weddings and receptions. Latest equipment and trending music.','₹18,000 onwards',4.4,62,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834400804' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Aadhithyan Nadaswaram','Arappalayam, Madurai West','9823400805','9823400805',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'gold',1,1,0,'Traditional Nadaswaram & Thavil by award-winning artists. Family troupe with 40+ years in temple and wedding performances.','₹15,000 onwards',4.6,74,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823400805' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Mel Vaadhiyam','Thiruppalai, Madurai East','9812400806','9812400806',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'silver',1,0,0,'Affordable traditional band and Kettimelam for all wedding ceremonies. Available for outstation events.','₹8,000 onwards',4.1,39,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9812400806' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Karthik Music Events','Thirumangalam, Madurai North','9801400807',NULL,
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'basic',0,0,0,'',NULL,3.7,13,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801400807' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Chennai Beats Event','Egmore, Chennai','9876500801','9876500801',
  (SELECT id FROM vv_categories WHERE name='Music Events' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Premier music event company. Full orchestra, live band, DJ, and Nadaswaram troupe under one roof. 5000+ events.','₹50,000 onwards',4.8,203,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500801' AND is_demo=1);

-- ── FLOWERS & GARLAND ─────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Ponni Flower Palace','Mattuthavani, Madurai','9876533444','9876533444',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Largest wholesale and retail flower supplier in Madurai. Fresh flowers daily from Kodaikanal and Munnar. Marigold garlands, jasmine strings, rose arrangements.','₹50,000 onwards',4.8,132,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876533444' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Rose Garden Flowers','Anna Nagar, Madurai East','9865400111','9865400111',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,0,'Imported rose garlands and fresh flower arrangements. Intricate flower artwork and unique wedding entrance decorations.','₹40,000 onwards',4.7,98,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400111' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Malligai Flower Works','KK Nagar, Madurai North','9843411103','9843411103',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Traditional jasmine and marigold garland specialists. Paal kudam, wedding car decoration, and full venue floral setup.','₹25,000 onwards',4.5,74,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411103' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Senthil Flower House','Anaiyur, Madurai South','9834411104','9834411104',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,0,0,'Fresh flower garlands and decoration for all budgets. Same-day delivery within Madurai city.','₹20,000 onwards',4.3,53,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834411104' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Poomalai Flower Shop','Kochadai, Madurai West','9823411105','9823411105',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Affordable flower garlands for weddings and all ceremonies. 24-hour advance booking required.','₹10,000 onwards',4.0,31,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411105' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Anbu Flower Stall','Thiruppalai, Madurai East','9801411106',NULL,
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'basic',0,0,0,'',NULL,3.6,9,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411106' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'T Nagar Flower Market','Usman Road, T Nagar, Chennai','9876500112','9876500112',
  (SELECT id FROM vv_categories WHERE name='Flowers & Garland' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'Chennai''s most trusted wedding flower supplier. 500+ weddings monthly. South Indian traditional and modern floral decorations.','₹60,000 onwards',4.9,221,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500112' AND is_demo=1);

-- ── SWEETS ────────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sri Krishna Sweets','Bypass Road, Madurai','9876566777','9876566777',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'35 years of authentic traditional sweets. Signature Mysorepak, Halwa, and wedding sweets. Pure ghee, fresh daily. Bulk orders with custom packaging.','₹650 per kg',4.9,312,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876566777' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Annapoorna Sweet Stall','Anna Nagar, Madurai East','9865400190','9865400190',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Wedding sweet boxes, return gift sweets. Jangiri, Athirasam, Putharekulu specialties.','₹580 per kg',4.8,267,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400190' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Thirunelveli Halwa Depot','KK Nagar, Madurai North','9843411903','9843411903',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Authentic Thirunelveli Halwa. Only outlet in Madurai with the original recipe. Perfect for wedding hampers.','₹700 per kg',4.7,189,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411903' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Palanisamy Sweets','Palanganatham, Madurai South','9834411904','9834411904',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,1,0,'Traditional homemade sweets. Nei Urundai, Adhirasam, and Kavuni Arisi sweet.','₹500 per kg',4.4,112,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834411904' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Madurai Mithai','Arappalayam, Madurai West','9823411905','9823411905',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Affordable sweet boxes. Wide variety of North and South Indian sweets available.','₹400 per kg',4.1,54,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411905' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Sweet Corner','Thirumangalam, Madurai North','9801411906',NULL,
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'basic',0,0,0,'',NULL,3.8,16,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411906' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Adyar Ananda Bhavan Sweets','T Nagar, Chennai','9876500190','9876500190',
  (SELECT id FROM vv_categories WHERE name='Sweets' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Chennai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Chennai Central' LIMIT 1),
  'platinum',1,1,1,'The iconic AAB chain. Premium quality wedding sweets, custom packaging, bulk order discounts. Delivery across Chennai.','₹750 per kg',4.9,456,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500190' AND is_demo=1);

-- ── TRAVELS ───────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Madurai Tours & Travels','Periyar Bus Stand Road, Madurai','9876555666','9876555666',
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,0,'Complete wedding transportation. AC buses, mini-vans, cars, luxury coaches. Guest transport, baraat, honeymoon packages. Fleet of 35.','₹3,500 per vehicle',4.5,76,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876555666' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'KPN Wedding Travels','Anna Nagar, Madurai East','9865400140','9865400140',
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'platinum',1,1,1,'Most trusted fleet operator for wedding transportation in South Tamil Nadu. Luxury coaches, AC buses, decorated cars, vintage car rentals. Fleet 50.','₹4,000 per vehicle',4.6,91,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400140' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vijay Travels','KK Nagar, Madurai North','9843411403','9843411403',
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Reliable and affordable wedding transportation. AC buses and mini-vans within Madurai and outstation.','₹2,800 per vehicle',4.3,58,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411403' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Travels','Tallakulam, Madurai South','9834411404','9834411404',
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'gold',1,0,0,'Budget-friendly wedding transport. AC and non-AC buses for outstation bookings.','₹2,500 per vehicle',4.2,43,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9834411404' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Senthil Cab Service','Arappalayam, Madurai West','9823411405','9823411405',
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Individual car bookings for wedding functions. Hatchback, sedan, and SUV options.','₹2,000 per vehicle',4.0,27,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411405' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Taxi Point Madurai','Anna Nagar, Madurai','9801411406',NULL,
  (SELECT id FROM vv_categories WHERE name='Travels' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'basic',0,0,0,'',NULL,3.7,14,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411406' AND is_demo=1);

-- ── SERVICE APARTMENTS ────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Comfort Stay Suites','Kalavasal, Madurai West','9876577888','9876577888',
  (SELECT id FROM vv_categories WHERE name='Service Apartments' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Premium service apartments for wedding guests. 20 fully furnished units, kitchen, AC, WiFi, 24/7 security. 2 km from major halls.','₹3,500 per night',4.6,87,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876577888' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Wedding Guest Residency','Anna Nagar, Madurai East','9865400120','9865400120',
  (SELECT id FROM vv_categories WHERE name='Service Apartments' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'gold',1,1,0,'Spacious serviced apartments for wedding guests. Group discounts for 5+ rooms. Complimentary breakfast and airport pickup.','₹2,500 per night',4.4,63,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400120' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'City Nest Apartments','KK Nagar, Madurai North','9843411203','9843411203',
  (SELECT id FROM vv_categories WHERE name='Service Apartments' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,1,0,'Budget service apartments near major wedding venues. All rooms AC with TV and kitchenette.','₹2,200 per night',4.2,48,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411203' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Ponmalar Guest House','Anaiyur, Madurai South','9823411204','9823411204',
  (SELECT id FROM vv_categories WHERE name='Service Apartments' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'silver',1,0,0,'Clean and comfortable rooms for wedding guests. Home-cooked breakfast available on request.','₹1,500 per night',4.0,29,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411204' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Ramu Lodging','Ponmeni, Madurai West','9801411205',NULL,
  (SELECT id FROM vv_categories WHERE name='Service Apartments' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.5,11,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411205' AND is_demo=1);

-- ── CRACKERS ──────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Standard Fireworks Depot','Bypass Road, Madurai','9876500160','9876500160',
  (SELECT id FROM vv_categories WHERE name='Crackers' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Most trusted cracker supplier in Madurai. Licensed dealer. Premium Sivakasi crackers. Wedding packages with professional lighting team.','₹25,000 onwards',4.7,143,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500160' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Veera Firecrackers','Anna Nagar, Madurai East','9865400160','9865400160',
  (SELECT id FROM vv_categories WHERE name='Crackers' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'gold',1,1,0,'Premium Sivakasi crackers for weddings, valaikappu, and ear-piercing ceremonies. Customised packages for every budget.','₹15,000 onwards',4.5,88,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400160' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Royal Crackers','KK Nagar, Madurai North','9843411603','9843411603',
  (SELECT id FROM vv_categories WHERE name='Crackers' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'gold',1,0,0,'Wide range of wedding crackers at competitive prices. Safe and licensed products from Sivakasi direct.','₹12,000 onwards',4.3,62,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411603' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Surya Crackers','Kochadai, Madurai West','9823411604','9823411604',
  (SELECT id FROM vv_categories WHERE name='Crackers' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'silver',1,0,0,'Budget cracker packages. Minimum order ₹5,000. Free delivery within Madurai city.','₹8,000 onwards',4.0,35,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9823411604' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Pandi Crackers','Tallakulam, Madurai South','9801411605',NULL,
  (SELECT id FROM vv_categories WHERE name='Crackers' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'basic',0,0,0,'',NULL,3.6,8,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411605' AND is_demo=1);

-- ── FURNITURE ─────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Wedding Furniture Rentals','Bypass Road, Madurai','9876500170','9876500170',
  (SELECT id FROM vv_categories WHERE name='Furniture' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Complete wedding furniture rental. Bridal sofas, decorated chairs, reception desks, mandap furniture. 500+ items. Delivery, setup, and pickup included.','₹50,000 onwards',4.6,98,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500170' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Classic Furniture Hire','Anna Nagar, Madurai East','9865400170','9865400170',
  (SELECT id FROM vv_categories WHERE name='Furniture' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'gold',1,1,0,'Premium decorated bridal chairs and sofas for hire. Gold and silver finish. Same-day delivery available.','₹30,000 onwards',4.4,67,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400170' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Murugan Furniture Works','KK Nagar, Madurai North','9843411703','9843411703',
  (SELECT id FROM vv_categories WHERE name='Furniture' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'silver',1,0,0,'Affordable furniture rental for wedding halls. Chairs, tables, and basic setup available.','₹15,000 onwards',4.0,38,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843411703' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Budget Furniture Rental','Arappalayam, Madurai','9801411704',NULL,
  (SELECT id FROM vv_categories WHERE name='Furniture' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'basic',0,0,0,'',NULL,3.4,7,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801411704' AND is_demo=1);

-- ── UTENSILS ──────────────────────────────────────────────────
INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Saravana Vessel Center','North Veli Street, Madurai','9876500200','9876500200',
  (SELECT id FROM vv_categories WHERE name='Utensils' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai West' LIMIT 1),
  'platinum',1,1,1,'Largest utensil rental store in Madurai. Stainless steel vessels, banana leaf holders, serving spoons, water pots. 10,000+ items in stock.','₹15,000 onwards',4.7,121,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9876500200' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Pandian Vessel Hire','Anna Nagar, Madurai East','9865400200','9865400200',
  (SELECT id FROM vv_categories WHERE name='Utensils' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai East' LIMIT 1),
  'gold',1,1,0,'Complete wedding kitchen equipment rental. Cooking vessels, serving items, dining equipment. Cleaned and sanitized before delivery.','₹10,000 onwards',4.5,84,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9865400200' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Vasuki Vessels','KK Nagar, Madurai North','9843412003','9843412003',
  (SELECT id FROM vv_categories WHERE name='Utensils' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai North' LIMIT 1),
  'silver',1,0,0,'Budget vessel rental for small weddings. All items cleaned and packed. Free delivery within 10 km.','₹6,000 onwards',4.1,46,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9843412003' AND is_demo=1);

INSERT INTO vv_vendors (name,full_address,mobile,whatsapp,category_id,city_id,region_id,membership_tier,is_verified,is_trusted,is_trending,description,amount,rating,rating_count,status,is_demo,created_at)
SELECT 'Rajan Vessel Store','Tallakulam, Madurai South','9801412004',NULL,
  (SELECT id FROM vv_categories WHERE name='Utensils' LIMIT 1),(SELECT id FROM vv_cities WHERE name='Madurai' LIMIT 1),(SELECT id FROM vv_regions WHERE name='Madurai South' LIMIT 1),
  'basic',0,0,0,'',NULL,3.5,9,'approved',1,1672531200
WHERE NOT EXISTS (SELECT 1 FROM vv_vendors WHERE mobile='9801412004' AND is_demo=1);

-- =============================================================
-- Demo vendor media (photos from Unsplash)
-- =============================================================
-- Photo URL shorthand (Unsplash)
-- P0=1519167758481  P1=1464366400600  P2=1511578314322  P3=1478146059778
-- P4=1606216794074  P5=1519741497674  P6=1465495976277  P7=1555244162803
-- P8=1504674900247  P9=1560869713     P10=1487530811015 P11=1493225457124
-- P12=1515934751635 P13=1522708323590 P14=1551024709     P15=1544620347
-- P16=1571266028243

CREATE OR REPLACE FUNCTION _vv_add_demo_photo(p_mobile TEXT, p_url TEXT) RETURNS void AS $$
DECLARE vid BIGINT;
BEGIN
  SELECT id INTO vid FROM vv_vendors WHERE mobile = p_mobile AND is_demo = 1;
  IF vid IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM vv_vendor_media WHERE vendor_id = vid AND url = p_url
  ) THEN
    INSERT INTO vv_vendor_media (vendor_id, type, url, created_at)
    VALUES (vid, 'image', p_url, 1672531200);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  p0  TEXT := 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400';
  p1  TEXT := 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=400';
  p2  TEXT := 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=400';
  p3  TEXT := 'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=400';
  p4  TEXT := 'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400';
  p5  TEXT := 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400';
  p6  TEXT := 'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=400';
  p7  TEXT := 'https://images.unsplash.com/photo-1555244162-803834f70033?w=400';
  p8  TEXT := 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400';
  p9  TEXT := 'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=400';
  p10 TEXT := 'https://images.unsplash.com/photo-1487530811015-780f2e6d0b5c?w=400';
  p11 TEXT := 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400';
  p12 TEXT := 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=400';
  p13 TEXT := 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400';
  p14 TEXT := 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400';
  p15 TEXT := 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400';
  p16 TEXT := 'https://images.unsplash.com/photo-1571266028243-e4733b0f0bb0?w=400';
BEGIN
  -- Mandapam
  PERFORM _vv_add_demo_photo('9876543210', p0); PERFORM _vv_add_demo_photo('9876543210', p1); PERFORM _vv_add_demo_photo('9876543210', p2);
  PERFORM _vv_add_demo_photo('9865432107', p0); PERFORM _vv_add_demo_photo('9865432107', p3);
  PERFORM _vv_add_demo_photo('9843210987', p1); PERFORM _vv_add_demo_photo('9843210987', p2);
  PERFORM _vv_add_demo_photo('9845671230', p1);
  PERFORM _vv_add_demo_photo('9867543210', p0);
  PERFORM _vv_add_demo_photo('9854321076', p3);
  PERFORM _vv_add_demo_photo('9876500001', p0); PERFORM _vv_add_demo_photo('9876500001', p1); PERFORM _vv_add_demo_photo('9876500001', p2); PERFORM _vv_add_demo_photo('9876500001', p3);
  PERFORM _vv_add_demo_photo('9865400002', p0); PERFORM _vv_add_demo_photo('9865400002', p3);
  PERFORM _vv_add_demo_photo('9843400003', p1); PERFORM _vv_add_demo_photo('9843400003', p2);
  -- Catering
  PERFORM _vv_add_demo_photo('9876012345', p7); PERFORM _vv_add_demo_photo('9876012345', p8);
  PERFORM _vv_add_demo_photo('9876098765', p7); PERFORM _vv_add_demo_photo('9876098765', p8);
  PERFORM _vv_add_demo_photo('9865432198', p8);
  PERFORM _vv_add_demo_photo('9845678901', p7);
  PERFORM _vv_add_demo_photo('9834567890', p7); PERFORM _vv_add_demo_photo('9834567890', p8);
  PERFORM _vv_add_demo_photo('9834512367', p8);
  PERFORM _vv_add_demo_photo('9812345001', p7);
  PERFORM _vv_add_demo_photo('9876500101', p7); PERFORM _vv_add_demo_photo('9876500101', p8);
  PERFORM _vv_add_demo_photo('9843400101', p7);
  -- Decorators
  PERFORM _vv_add_demo_photo('9876500111', p3); PERFORM _vv_add_demo_photo('9876500111', p2);
  PERFORM _vv_add_demo_photo('9865400222', p3); PERFORM _vv_add_demo_photo('9865400222', p2); PERFORM _vv_add_demo_photo('9865400222', p1);
  PERFORM _vv_add_demo_photo('9843400333', p3);
  PERFORM _vv_add_demo_photo('9834400444', p2); PERFORM _vv_add_demo_photo('9834400444', p3);
  PERFORM _vv_add_demo_photo('9823400555', p3);
  PERFORM _vv_add_demo_photo('9876500301', p3); PERFORM _vv_add_demo_photo('9876500301', p2); PERFORM _vv_add_demo_photo('9876500301', p1); PERFORM _vv_add_demo_photo('9876500301', p0);
  PERFORM _vv_add_demo_photo('9843400301', p3);
  -- Makeup Artist
  PERFORM _vv_add_demo_photo('9876511222', p9);
  PERFORM _vv_add_demo_photo('9865411333', p9);
  PERFORM _vv_add_demo_photo('9843411444', p9);
  PERFORM _vv_add_demo_photo('9834411555', p9);
  PERFORM _vv_add_demo_photo('9876500401', p9);
  PERFORM _vv_add_demo_photo('9843400401', p9);
  -- Photography
  PERFORM _vv_add_demo_photo('9876543099', p4); PERFORM _vv_add_demo_photo('9876543099', p5); PERFORM _vv_add_demo_photo('9876543099', p6);
  PERFORM _vv_add_demo_photo('9865400502', p5); PERFORM _vv_add_demo_photo('9865400502', p6);
  PERFORM _vv_add_demo_photo('9843400503', p4); PERFORM _vv_add_demo_photo('9843400503', p5);
  PERFORM _vv_add_demo_photo('9834400504', p6);
  PERFORM _vv_add_demo_photo('9823400505', p5);
  PERFORM _vv_add_demo_photo('9812400506', p4);
  PERFORM _vv_add_demo_photo('9876500501', p4); PERFORM _vv_add_demo_photo('9876500501', p5); PERFORM _vv_add_demo_photo('9876500501', p6);
  PERFORM _vv_add_demo_photo('9843400501', p5); PERFORM _vv_add_demo_photo('9843400501', p6);
  -- Invitation Cards
  PERFORM _vv_add_demo_photo('9876544555', p12);
  PERFORM _vv_add_demo_photo('9865400602', p12);
  PERFORM _vv_add_demo_photo('9843400603', p12);
  -- Music Events
  PERFORM _vv_add_demo_photo('9876522333', p11);
  PERFORM _vv_add_demo_photo('9865400802', p11);
  PERFORM _vv_add_demo_photo('9843400803', p16);
  PERFORM _vv_add_demo_photo('9834400804', p16);
  PERFORM _vv_add_demo_photo('9876500801', p11); PERFORM _vv_add_demo_photo('9876500801', p16);
  -- Flowers & Garland
  PERFORM _vv_add_demo_photo('9876533444', p10);
  PERFORM _vv_add_demo_photo('9865400111', p10);
  PERFORM _vv_add_demo_photo('9843411103', p10);
  PERFORM _vv_add_demo_photo('9876500112', p10);
  -- Sweets
  PERFORM _vv_add_demo_photo('9876566777', p14);
  PERFORM _vv_add_demo_photo('9865400190', p14);
  PERFORM _vv_add_demo_photo('9843411903', p14);
  PERFORM _vv_add_demo_photo('9876500190', p14);
  -- Travels
  PERFORM _vv_add_demo_photo('9876555666', p15);
  PERFORM _vv_add_demo_photo('9865400140', p15);
  -- Service Apartments
  PERFORM _vv_add_demo_photo('9876577888', p13);
  PERFORM _vv_add_demo_photo('9865400120', p13);
END $$;

DROP FUNCTION IF EXISTS _vv_add_demo_photo(TEXT, TEXT);
