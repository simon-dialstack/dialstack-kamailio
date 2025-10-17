-- kamailio/test-schema.sql
-- Minimal schema for local Kamailio testing
-- This matches the production schema structure from infra/environments/database/migrations/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create minimal tenants table
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(63) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create minimal users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create endpoints table (matches production schema)
CREATE TABLE IF NOT EXISTS endpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- SIP credentials (unique per device)
    sip_username VARCHAR(255) NOT NULL,
    sip_password VARCHAR(255) NOT NULL,
    sip_realm VARCHAR(255) DEFAULT 'dialstack.ai',

    -- Device info
    device_name VARCHAR(255),

    -- Registration status (updated by Kamailio)
    is_registered BOOLEAN DEFAULT FALSE,
    registered_at TIMESTAMPTZ,
    registration_expires_at TIMESTAMPTZ,
    registered_contact VARCHAR(500),
    registered_ip INET,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, sip_username)
);

CREATE INDEX idx_endpoints_sip_username ON endpoints(sip_username);
CREATE INDEX idx_endpoints_registered ON endpoints(is_registered) WHERE is_registered = TRUE;

-- Kamailio's version table (tracks schema versions for various tables)
CREATE TABLE IF NOT EXISTS version (
    table_name VARCHAR(32) NOT NULL,
    table_version INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT version_table_name_idx UNIQUE (table_name)
);

-- Kamailio's location table (usrloc with db_mode=2 writes here)
CREATE TABLE IF NOT EXISTS location (
    id SERIAL PRIMARY KEY,
    ruid VARCHAR(64) DEFAULT '' NOT NULL,
    username VARCHAR(64) DEFAULT '' NOT NULL,
    domain VARCHAR(64) DEFAULT NULL,
    contact VARCHAR(512) DEFAULT '' NOT NULL,
    received VARCHAR(128) DEFAULT NULL,
    path VARCHAR(512) DEFAULT NULL,
    expires TIMESTAMPTZ DEFAULT '2030-05-28 21:32:15' NOT NULL,
    q REAL DEFAULT 1.0 NOT NULL,
    callid VARCHAR(255) DEFAULT 'Default-Call-ID' NOT NULL,
    cseq INTEGER DEFAULT 1 NOT NULL,
    last_modified TIMESTAMPTZ DEFAULT '2000-01-01 00:00:01' NOT NULL,
    flags INTEGER DEFAULT 0 NOT NULL,
    cflags INTEGER DEFAULT 0 NOT NULL,
    user_agent VARCHAR(255) DEFAULT '' NOT NULL,
    socket VARCHAR(64) DEFAULT NULL,
    methods INTEGER DEFAULT NULL,
    instance VARCHAR(255) DEFAULT NULL,
    reg_id INTEGER DEFAULT 0 NOT NULL,
    server_id INTEGER DEFAULT 0 NOT NULL,
    connection_id INTEGER DEFAULT 0 NOT NULL,
    keepalive INTEGER DEFAULT 0 NOT NULL,
    partition INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT location_ruid_idx UNIQUE (ruid)
);

CREATE INDEX location_account_contact_idx ON location (username, domain, contact);
CREATE INDEX location_expires_idx ON location (expires);

-- Register the location table version (usrloc expects version 9)
INSERT INTO version (table_name, table_version) VALUES ('location', 9);

-- Register the endpoints table version (auth_db subscriber table uses version 7)
INSERT INTO version (table_name, table_version) VALUES ('subscriber', 7);

-- Create test tenant
INSERT INTO tenants (id, name, subdomain)
VALUES (
    'f8a01e16-0372-4ef6-ad45-a7559b00770d',
    'Test Company',
    'testco'
);

-- Create test user
INSERT INTO users (id, tenant_id, name, email)
VALUES (
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'f8a01e16-0372-4ef6-ad45-a7559b00770d',
    'Test User',
    'test@example.com'
);

-- Create test endpoint with SIP credentials
INSERT INTO endpoints (tenant_id, user_id, sip_username, sip_password, sip_realm, device_name)
VALUES (
    'f8a01e16-0372-4ef6-ad45-a7559b00770d',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'testuser',
    'testpass123',
    'dialstack.ai',
    'Test Softphone'
);
