-- =============================================================
-- VV — Fix Duplicates & Add Unique Constraints
-- Run this ONCE in Supabase SQL Editor to clean up duplicates
-- caused by running supabase_schema.sql multiple times.
-- =============================================================

-- ── 1. Fix duplicate CITIES ───────────────────────────────────
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT name, MIN(id) AS keep_id, array_agg(id ORDER BY id) AS all_ids
    FROM vv_cities GROUP BY name HAVING COUNT(*) > 1
  LOOP
    -- Re-point vendor & region FK references to the kept row
    UPDATE vv_vendors SET city_id  = r.keep_id WHERE city_id  = ANY(r.all_ids) AND city_id  != r.keep_id;
    UPDATE vv_regions  SET city_id  = r.keep_id WHERE city_id  = ANY(r.all_ids) AND city_id  != r.keep_id;
    -- Delete the duplicates
    DELETE FROM vv_cities WHERE id = ANY(r.all_ids) AND id != r.keep_id;
  END LOOP;
END $$;

-- ── 2. Fix duplicate CATEGORIES ───────────────────────────────
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT name, MIN(id) AS keep_id, array_agg(id ORDER BY id) AS all_ids
    FROM vv_categories GROUP BY name HAVING COUNT(*) > 1
  LOOP
    UPDATE vv_vendors SET category_id = r.keep_id WHERE category_id = ANY(r.all_ids) AND category_id != r.keep_id;
    DELETE FROM vv_categories WHERE id = ANY(r.all_ids) AND id != r.keep_id;
  END LOOP;
END $$;

-- ── 3. Fix duplicate REGIONS ───────────────────────────────���──
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT city_id, name, MIN(id) AS keep_id, array_agg(id ORDER BY id) AS all_ids
    FROM vv_regions GROUP BY city_id, name HAVING COUNT(*) > 1
  LOOP
    UPDATE vv_vendors SET region_id = r.keep_id WHERE region_id = ANY(r.all_ids) AND region_id != r.keep_id;
    DELETE FROM vv_regions WHERE id = ANY(r.all_ids) AND id != r.keep_id;
  END LOOP;
END $$;

-- ── 4. Fix duplicate demo VENDORS (same mobile + is_demo=1) ───
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT mobile, MIN(id) AS keep_id, array_agg(id ORDER BY id) AS all_ids
    FROM vv_vendors WHERE is_demo = 1 GROUP BY mobile HAVING COUNT(*) > 1
  LOOP
    -- Move media from duplicates to the kept vendor
    UPDATE vv_vendor_media SET vendor_id = r.keep_id WHERE vendor_id = ANY(r.all_ids) AND vendor_id != r.keep_id;
    -- Delete duplicates
    DELETE FROM vv_vendors WHERE id = ANY(r.all_ids) AND id != r.keep_id;
  END LOOP;
END $$;

-- ── 5. Add UNIQUE constraints (safe to re-run) ────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'vv_cities_name_key'
  ) THEN
    ALTER TABLE vv_cities ADD CONSTRAINT vv_cities_name_key UNIQUE (name);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'vv_categories_name_key'
  ) THEN
    ALTER TABLE vv_categories ADD CONSTRAINT vv_categories_name_key UNIQUE (name);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'vv_regions_city_name_key'
  ) THEN
    ALTER TABLE vv_regions ADD CONSTRAINT vv_regions_city_name_key UNIQUE (city_id, name);
  END IF;
END $$;

-- ── Done ───────────────────────────────────────────────────��──
SELECT
  (SELECT COUNT(*) FROM vv_cities)     AS cities,
  (SELECT COUNT(*) FROM vv_categories) AS categories,
  (SELECT COUNT(*) FROM vv_regions)    AS regions,
  (SELECT COUNT(*) FROM vv_vendors WHERE is_demo = 1) AS demo_vendors;
