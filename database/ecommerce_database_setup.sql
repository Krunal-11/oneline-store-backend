-- Enable UUID generation (for unique IDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable trigram matching (for fuzzy search like "prestige" vs "prestge")
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Verify extensions are installed
SELECT extname, extversion FROM pg_extension WHERE extname IN ('uuid-ossp', 'pg_trgm');

-- ===============================================
-- CORE TABLES: Categories, Brands, Product Groups
-- ===============================================

-- 1. CATEGORIES TABLE (Hierarchical structure)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    parent_id UUID REFERENCES categories(id),
    path TEXT,
    level INTEGER DEFAULT 0,
    display_order INTEGER DEFAULT 0,
    icon_url TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. BRANDS TABLE
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    logo_url TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. PRODUCT GROUPS TABLE (Parent products for variants)
CREATE TABLE product_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    category_id UUID NOT NULL REFERENCES categories(id),
    brand_id UUID NOT NULL REFERENCES brands(id),
    base_price DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    is_featured BOOLEAN DEFAULT false,
    search_keywords TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify tables created
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- ===============================================
-- PRODUCT AND IMAGE TABLES
-- ===============================================

-- 4. PRODUCTS TABLE (Individual variants)
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_group_id UUID NOT NULL REFERENCES product_groups(id) ON DELETE CASCADE,
    sku VARCHAR(100) UNIQUE,
    variant_name VARCHAR(100),
    mrp DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    attributes JSONB,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    stock_quantity INTEGER DEFAULT 0,
    is_default_variant BOOLEAN DEFAULT false,
    meta_title VARCHAR(200),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. PRODUCT IMAGES TABLE
CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    cloudinary_url TEXT NOT NULL,
    alt_text VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    image_type VARCHAR(20) DEFAULT 'PRODUCT',
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify new tables created
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- ===============================================
-- USER AUTHENTICATION TABLES
-- ===============================================

-- 6. USERS TABLE (Phone-based authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL UNIQUE,
    name VARCHAR(100),
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'USER',
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. OTP VERIFICATIONS TABLE
CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) DEFAULT 'LOGIN',
    attempts INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. WISHLISTS TABLE (Anonymous + authenticated support)
CREATE TABLE wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_user_product UNIQUE(user_id, product_id),
    CONSTRAINT unique_session_product UNIQUE(session_id, product_id)
);

-- Verify new tables created
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- ===============================================
-- ANALYTICS & PERFORMANCE TABLES
-- ===============================================

-- 9. PRODUCT VIEWS TABLE (Analytics tracking)
CREATE TABLE product_views (
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    viewed_at DATE NOT NULL DEFAULT CURRENT_DATE,
    view_count INTEGER DEFAULT 1,
    PRIMARY KEY (product_id, viewed_at)
);

-- 10. CATEGORY BRANDS TABLE (Search performance optimization)
CREATE TABLE category_brands (
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    product_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (category_id, brand_id)
);

-- Final verification - should show 10 tables total
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- ===============================================
-- PERFORMANCE INDEXES
-- ===============================================

-- Category hierarchy indexes
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_path ON categories USING GIN(path gin_trgm_ops);
CREATE INDEX idx_categories_active ON categories(is_active, display_order);

-- Brand fuzzy search indexes
CREATE INDEX idx_brands_name_trgm ON brands USING GIN(name gin_trgm_ops);

-- Product group search indexes (CRITICAL for performance)
CREATE INDEX idx_product_groups_name_trgm ON product_groups USING GIN(name gin_trgm_ops);
CREATE INDEX idx_product_groups_search ON product_groups USING GIN(
    to_tsvector('english', name || ' ' || COALESCE(search_keywords, ''))
);
CREATE INDEX idx_product_groups_category ON product_groups(category_id, status);
CREATE INDEX idx_product_groups_brand ON product_groups(brand_id, status);
CREATE INDEX idx_product_groups_featured ON product_groups(is_featured, created_at) WHERE status = 'ACTIVE';

-- Product variant indexes
CREATE INDEX idx_products_group ON products(product_group_id, status);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_attributes ON products USING GIN(attributes);
CREATE INDEX idx_products_default ON products(is_default_variant) WHERE is_default_variant = true;

-- Product image indexes
CREATE INDEX idx_product_images_product ON product_images(product_id, display_order);
CREATE INDEX idx_product_images_primary ON product_images(product_id, is_primary) WHERE is_primary = true;

-- User indexes
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role, is_active);

-- OTP indexes
CREATE INDEX idx_otp_phone_expiry ON otp_verifications(phone, expires_at) WHERE is_verified = false;

-- Wishlist indexes
CREATE INDEX idx_wishlists_user ON wishlists(user_id);
CREATE INDEX idx_wishlists_session ON wishlists(session_id);

-- Analytics indexes
CREATE INDEX idx_product_views_date ON product_views(viewed_at DESC);
CREATE INDEX idx_product_views_count ON product_views(view_count DESC, viewed_at DESC);

-- Category-brand performance indexes
CREATE INDEX idx_category_brands_category ON category_brands(category_id, product_count DESC);
CREATE INDEX idx_category_brands_brand ON category_brands(brand_id, product_count DESC);

-- Verification: List all indexes created
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;



-- ===============================================
-- SAMPLE DATA FOR TESTING
-- ===============================================

-- Insert sample categories (hierarchical structure)
INSERT INTO categories (id, name, slug, parent_id, path, level, display_order) VALUES
('11111111-1111-1111-1111-111111111111', 'Electronics', 'electronics', NULL, '/electronics/', 0, 1),
('22222222-2222-2222-2222-222222222222', 'Kitchen Essentials', 'kitchen-essentials', NULL, '/kitchen-essentials/', 0, 2),
('33333333-3333-3333-3333-333333333333', 'Mixer Grinder', 'mixer-grinder', '11111111-1111-1111-1111-111111111111', '/electronics/mixer-grinder/', 1, 1),
('44444444-4444-4444-4444-444444444444', 'Pressure Cooker', 'pressure-cooker', '22222222-2222-2222-2222-222222222222', '/kitchen-essentials/pressure-cooker/', 1, 1),
('55555555-5555-5555-5555-555555555555', '3 Jar', '3-jar', '33333333-3333-3333-3333-333333333333', '/electronics/mixer-grinder/3-jar/', 2, 1),
('66666666-6666-6666-6666-666666666666', 'Steel Base', 'steel-base', '44444444-4444-4444-4444-444444444444', '/kitchen-essentials/pressure-cooker/steel-base/', 2, 1);

-- Insert sample brands
INSERT INTO brands (id, name, slug, description) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Prestige', 'prestige', 'Premium kitchen appliances brand'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Bajaj', 'bajaj', 'Trusted Indian electronics brand'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Preethi', 'preethi', 'South Indian kitchen appliance specialist');

-- Insert sample product groups
INSERT INTO product_groups (id, name, slug, description, category_id, brand_id, base_price, search_keywords) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Prestige Deluxe Alpha Pressure Cooker', 'prestige-deluxe-alpha-pressure-cooker', 'Premium stainless steel pressure cooker with safety features', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2500.00, 'cooker kitchen pressure stainless steel cooking'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Bajaj Rex Mixer Grinder 750W', 'bajaj-rex-mixer-grinder-750w', 'Powerful 750W mixer grinder with 3 jars', '55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 3200.00, 'mixer grinder jar blending grinding spices'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Preethi Blue Leaf Diamond Mixer', 'preethi-blue-leaf-diamond-mixer', 'Diamond-coated mixer grinder for superior grinding', '55555555-5555-5555-5555-555555555555', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 4500.00, 'mixer grinder diamond coating premium');

-- Insert sample products (variants)
INSERT INTO products (id, product_group_id, sku, variant_name, mrp, selling_price, attributes, is_default_variant) VALUES
('12121212-1212-1212-1212-121212121212', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'PRE-DLX-ALP-2L', '2 Litre', 3000.00, 2500.00, '{"size": "2L", "material": "Stainless Steel", "warranty": "5 years"}', true),
('13131313-1313-1313-1313-131313131313', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'PRE-DLX-ALP-3L', '3 Litre', 3500.00, 2900.00, '{"size": "3L", "material": "Stainless Steel", "warranty": "5 years"}', false),
('14141414-1414-1414-1414-141414141414', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'PRE-DLX-ALP-5L', '5 Litre', 4500.00, 3800.00, '{"size": "5L", "material": "Stainless Steel", "warranty": "5 years"}', false),
('15151515-1515-1515-1515-151515151515', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'BAJ-REX-750W', 'Standard', 4000.00, 3200.00, '{"power": "750W", "jars": "3", "warranty": "2 years"}', true),
('16161616-1616-1616-1616-161616161616', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'PRT-BLD-DMD', 'Diamond Series', 5500.00, 4500.00, '{"coating": "Diamond", "jars": "4", "warranty": "3 years"}', true);

-- Insert sample users
INSERT INTO users (id, phone, name, role, is_verified) VALUES
('99999999-9999-9999-9999-999999999999', '+919876543210', 'Test User', 'USER', true),
('88888888-8888-8888-8888-888888888888', '+919876543211', 'Admin User', 'ADMIN', true);

-- Insert category-brand relationships for performance
INSERT INTO category_brands (category_id, brand_id, product_count) VALUES
('44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1),
('55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1),
('55555555-5555-5555-5555-555555555555', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 1);

-- Verification queries
SELECT 'Sample data inserted successfully!' as status;
SELECT 'Categories:', COUNT(*) FROM categories;
SELECT 'Brands:', COUNT(*) FROM brands;
SELECT 'Product Groups:', COUNT(*) FROM product_groups;
SELECT 'Products:', COUNT(*) FROM products;
SELECT 'Users:', COUNT(*) FROM users;
SELECT * FROM products;


