const fs   = require('fs');
const path = require('path');

let _supabase    = null;
let _configError = null;

// ------------------------------------------------------------------
// Config helpers
// ------------------------------------------------------------------

function getConfig() {
  const configPath = path.join(__dirname, '../data/config.json');
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {
    return { supabase_url: '', supabase_key: '', port: 4001, session_secret: 'vv-admin-secret' };
  }
}

function saveConfig(updates) {
  const configPath = path.join(__dirname, '../data/config.json');
  const current = getConfig();
  fs.writeFileSync(configPath, JSON.stringify({ ...current, ...updates }, null, 2));
}

// ------------------------------------------------------------------
// Connect
// ------------------------------------------------------------------

function connect(url, key) {
  const config = getConfig();
  const supabaseUrl = url || config.supabase_url;
  const supabaseKey = key || config.supabase_key;

  if (!supabaseUrl || !supabaseKey) {
    _configError = 'Supabase URL and key are not configured. Open Settings to set them.';
    console.warn(`\n⚠  ${_configError}\n`);
    return { success: false, error: _configError };
  }

  const { createClient } = require('@supabase/supabase-js');
  _supabase    = createClient(supabaseUrl, supabaseKey);
  _configError = null;
  return { success: true };
}

function getClient() {
  if (!_supabase) {
    const msg = _configError || 'Database not configured. Open Settings.';
    throw new Error(msg);
  }
  return _supabase;
}

function getConfigError() { return _configError; }
function isConnected()    { return !!_supabase && !_configError; }

// ------------------------------------------------------------------
// Test connection (Settings page)
// ------------------------------------------------------------------

async function testConnection(supabaseUrl, supabaseKey) {
  try {
    if (!supabaseUrl || !supabaseKey) {
      return { success: false, message: 'URL and key are required.' };
    }
    const { createClient } = require('@supabase/supabase-js');
    const client = createClient(supabaseUrl, supabaseKey);
    const { error } = await client.from('vv_vendors').select('id').limit(1);
    if (error) return { success: false, message: error.message };
    return { success: true, message: `Supabase connected to ${supabaseUrl}` };
  } catch (err) {
    return { success: false, message: err.message };
  }
}

// ------------------------------------------------------------------
// Query helpers  (thin wrappers so routes stay readable)
// ------------------------------------------------------------------

// Run a callback (fn) against the supabase client and throw on error
async function run(fn) {
  const sb = getClient();
  const { data, error, count } = await fn(sb);
  if (error) throw new Error(error.message);
  return count !== undefined ? { data, count } : data;
}

// Flatten embedded Supabase relations into flat column aliases
// e.g.  { category: { name: 'Catering' } }  →  category_name: 'Catering'
function flatten(row) {
  if (!row) return null;
  const out = { ...row };
  for (const [k, v] of Object.entries(out)) {
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      for (const [subk, subv] of Object.entries(v)) {
        out[`${k}_${subk}`] = subv;
      }
      delete out[k];
    }
  }
  return out;
}

function flattenAll(rows) {
  return (rows || []).map(flatten);
}

// ------------------------------------------------------------------
// Audit log
// ------------------------------------------------------------------

function logAction(adminUsername, action, entityType, entityId, details, ipAddress) {
  const sb = _supabase;
  if (!sb) return;
  const detailsStr = details && typeof details === 'object' ? JSON.stringify(details) : (details || null);
  sb.from('vv_admin_audit_log').insert({
    admin_username: adminUsername,
    action,
    entity_type:  entityType  || null,
    entity_id:    entityId    ? String(entityId) : null,
    details:      detailsStr,
    ip_address:   ipAddress   || null,
    created_at:   Math.floor(Date.now() / 1000),
  }).then(({ error }) => {
    if (error) console.error('Audit log error:', error.message);
  });
}

module.exports = {
  connect,
  getClient,
  getConfigError,
  isConnected,
  run,
  flatten,
  flattenAll,
  testConnection,
  logAction,
  getConfig,
  saveConfig,
};
