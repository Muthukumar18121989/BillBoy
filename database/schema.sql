-- BillBoy PostgreSQL Schema
-- Version: 1.0.0

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For full-text search

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid VARCHAR(128) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  photo_url TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  fcm_token TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(100),
  color VARCHAR(20),
  is_system BOOLEAN DEFAULT FALSE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bills Table
CREATE TABLE IF NOT EXISTS bills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_name VARCHAR(500) NOT NULL,
  category VARCHAR(100) NOT NULL,
  brand_name VARCHAR(255),
  model_number VARCHAR(255),
  serial_number VARCHAR(255),
  imei_number VARCHAR(20),
  purchase_date DATE NOT NULL,
  bill_number VARCHAR(255),
  purchase_amount DECIMAL(12, 2) NOT NULL,
  tax_amount DECIMAL(12, 2),
  current_value DECIMAL(12, 2),
  store_name VARCHAR(255),
  store_address TEXT,
  gst_number VARCHAR(20),
  warranty_months INTEGER,
  warranty_start_date DATE,
  warranty_end_date DATE,
  warranty_status VARCHAR(20) DEFAULT 'noWarranty'
    CHECK (warranty_status IN ('active', 'expiringSoon', 'expired', 'noWarranty')),
  attachment_urls TEXT[] DEFAULT '{}',
  thumbnail_url TEXT,
  ocr_text TEXT,
  notes TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Warranties Table
CREATE TABLE IF NOT EXISTS warranties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  duration_months INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active', 'expiringSoon', 'expired')),
  extended_warranty_date DATE,
  provider_name VARCHAR(255),
  document_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bill_id UUID REFERENCES bills(id) ON DELETE SET NULL,
  type VARCHAR(50) NOT NULL
    CHECK (type IN ('warranty_expiry', 'system', 'reminder')),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  channel VARCHAR(20) DEFAULT 'push'
    CHECK (channel IN ('push', 'email', 'sms')),
  scheduled_at TIMESTAMP WITH TIME ZONE,
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Depreciation Rules Table
CREATE TABLE IF NOT EXISTS depreciation_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category VARCHAR(100) NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rates_per_year FLOAT[] NOT NULL,
  is_custom BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OCR Results Table
CREATE TABLE IF NOT EXISTS ocr_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  raw_text TEXT,
  extracted_data JSONB,
  confidence FLOAT,
  processing_time_ms INTEGER,
  provider VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Preferences Table
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency VARCHAR(10) DEFAULT 'INR',
  theme_mode VARCHAR(10) DEFAULT 'system'
    CHECK (theme_mode IN ('light', 'dark', 'system')),
  visible_columns TEXT[] DEFAULT '{}',
  email_notifications BOOLEAN DEFAULT TRUE,
  push_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  custom_depreciation_rules JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  action VARCHAR(100) NOT NULL,
  resource VARCHAR(100),
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bills_user_id ON bills(user_id);
CREATE INDEX IF NOT EXISTS idx_bills_category ON bills(category);
CREATE INDEX IF NOT EXISTS idx_bills_warranty_end ON bills(warranty_end_date) WHERE warranty_end_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bills_warranty_status ON bills(warranty_status);
CREATE INDEX IF NOT EXISTS idx_bills_purchase_date ON bills(purchase_date);
CREATE INDEX IF NOT EXISTS idx_bills_is_deleted ON bills(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bills_product_name_trgm ON bills USING gin(product_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_bills_serial_number ON bills(serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bills_gst_number ON bills(gst_number) WHERE gst_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at) WHERE sent_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read, user_id);
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['users', 'bills', 'warranties', 'notifications', 'user_preferences', 'categories', 'ocr_results']
  LOOP
    EXECUTE format('
      CREATE TRIGGER update_%s_updated_at
      BEFORE UPDATE ON %s
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ', t, t);
  END LOOP;
END;
$$;

-- Seed default system categories
INSERT INTO categories (id, name, icon, color, is_system) VALUES
  (uuid_generate_v4(), 'Electronics', 'devices', '#6C63FF', TRUE),
  (uuid_generate_v4(), 'Mobile Phones', 'smartphone', '#42A5F5', TRUE),
  (uuid_generate_v4(), 'Laptops', 'laptop', '#26C6DA', TRUE),
  (uuid_generate_v4(), 'Appliances', 'kitchen', '#66BB6A', TRUE),
  (uuid_generate_v4(), 'Furniture', 'chair', '#FFB74D', TRUE),
  (uuid_generate_v4(), 'Fashion', 'checkroom', '#FF7043', TRUE),
  (uuid_generate_v4(), 'Jewelry', 'diamond', '#FFCA28', TRUE),
  (uuid_generate_v4(), 'Vehicles', 'directions_car', '#8D6E63', TRUE),
  (uuid_generate_v4(), 'Home Equipment', 'home_repair_service', '#78909C', TRUE),
  (uuid_generate_v4(), 'Insurance', 'health_and_safety', '#AB47BC', TRUE),
  (uuid_generate_v4(), 'Healthcare', 'medical_services', '#EF5350', TRUE),
  (uuid_generate_v4(), 'Grocery', 'shopping_basket', '#26A69A', TRUE),
  (uuid_generate_v4(), 'Subscription Services', 'subscriptions', '#7E57C2', TRUE),
  (uuid_generate_v4(), 'Others', 'receipt_long', '#90A4AE', TRUE)
ON CONFLICT DO NOTHING;
