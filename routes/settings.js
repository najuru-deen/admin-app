const express = require('express');
const router  = express.Router();
const { getClient, getConfig, saveConfig, testConnection, logAction } = require('../db/connection');
const { requireAuth } = require('../middleware/auth');

// Default: redirect to Cities & Regions
router.get('/', requireAuth, (req, res) => res.redirect('/settings/cities'));

// ── Cities & Regions ─────────────────────────────────────────
router.get('/cities', requireAuth, async (req, res) => {
  try {
    const sb = getClient();
    const [{ data: cities }, { data: regions }] = await Promise.all([
      sb.from('vv_cities').select('*').order('name'),
      sb.from('vv_regions').select('*').order('name'),
    ]);
    res.render('settings-cities', { title: 'Cities & Regions', cities: cities || [], regions: regions || [] });
  } catch (err) {
    req.flash('error', err.message);
    res.render('settings-cities', { title: 'Cities & Regions', cities: [], regions: [] });
  }
});

// ── Categories ───────────────────────────────────────────────
router.get('/categories', requireAuth, async (req, res) => {
  try {
    const sb = getClient();
    const { data: categories } = await sb.from('vv_categories').select('*').order('name');
    res.render('settings-categories', { title: 'Categories', categories: categories || [] });
  } catch (err) {
    req.flash('error', err.message);
    res.render('settings-categories', { title: 'Categories', categories: [] });
  }
});

// ── System — password re-verify ──────────────────────────────
const SYSTEM_UNLOCK_TTL = 15 * 60 * 1000; // 15 minutes

router.get('/system/verify', requireAuth, (req, res) => {
  res.render('settings-verify', { title: 'Confirm Identity' });
});

router.post('/system/verify', requireAuth, async (req, res) => {
  const { password } = req.body;
  try {
    const sb = getClient();
    const { data: admin } = await sb.from('vv_admin_users')
      .select('password').eq('username', req.session.user.username).single();
    if (!admin || admin.password !== password) {
      req.flash('error', 'Incorrect password. Please try again.');
      return res.redirect('/settings/system/verify');
    }
    req.session.systemUnlockedAt = Date.now();
    res.redirect('/settings/system');
  } catch (err) {
    req.flash('error', err.message);
    res.redirect('/settings/system/verify');
  }
});

router.get('/system', requireAuth, async (req, res) => {
  const unlocked = req.session.systemUnlockedAt && (Date.now() - req.session.systemUnlockedAt < SYSTEM_UNLOCK_TTL);
  if (!unlocked) return res.redirect('/settings/system/verify');
  const config = getConfig();
  try {
    const sb = getClient();
    const [
      { data: adminUsers }, { data: settingsRows }, { count: demoCount },
    ] = await Promise.all([
      sb.from('vv_admin_users').select('id, username, created_at').order('username'),
      sb.from('vv_settings').select('*'),
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }).eq('is_demo', 1),
    ]);
    const settings = {};
    for (const s of (settingsRows || [])) settings[s.key] = s.value;
    res.render('settings-system', { title: 'System Settings', config, adminUsers: adminUsers || [], settings, demoCount: demoCount || 0 });
  } catch (err) {
    res.render('settings-system', { title: 'System Settings', config, adminUsers: [], settings: {}, demoCount: 0 });
  }
});

// Public API — settings readable by mobile app without auth
router.get('/api', async (req, res) => {
  try {
    const sb = getClient();
    const { data } = await sb.from('vv_settings').select('key, value');
    const out = {};
    for (const s of (data || [])) out[s.key] = s.value;
    res.json(out);
  } catch (err) {
    res.json({});
  }
});

router.post('/db', requireAuth, async (req, res) => {
  const { supabase_url, supabase_key } = req.body;
  if (!supabase_url || !supabase_key) { req.flash('error', 'URL and key are required.'); return res.redirect('/settings/system'); }
  const test = await testConnection(supabase_url, supabase_key);
  if (!test.success) { req.flash('error', `Connection failed: ${test.message}`); return res.redirect('/settings/system'); }
  saveConfig({ supabase_url, supabase_key });
  logAction(req.session.user.username, 'UPDATE_DB_CONFIG', 'settings', null, { supabase_url }, req.ip);
  req.flash('success', `Saved. ${test.message}. Restart the server to apply.`);
  res.redirect('/settings/system');
});

router.post('/test-db', requireAuth, async (req, res) => {
  const result = await testConnection(req.body.supabase_url, req.body.supabase_key);
  res.json(result);
});

router.post('/admin/add', requireAuth, async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) { req.flash('error', 'Username and password required.'); return res.redirect('/settings/system'); }
  const sb = getClient();
  const { error } = await sb.from('vv_admin_users').insert({ username, password, created_at: Math.floor(Date.now()/1000) });
  if (error) { req.flash('error', error.message.includes('unique') ? `"${username}" already exists.` : error.message); }
  else { logAction(req.session.user.username, 'ADD_ADMIN_USER', null, null, { username }, req.ip); req.flash('success', `Admin "${username}" created.`); }
  res.redirect('/settings/system');
});

router.post('/admin/:id/change-password', requireAuth, async (req, res) => {
  const { password } = req.body;
  if (!password) { req.flash('error', 'Password required.'); return res.redirect('/settings/system'); }
  const sb = getClient();
  const { data: a } = await sb.from('vv_admin_users').select('username').eq('id', req.params.id).single();
  await sb.from('vv_admin_users').update({ password }).eq('id', req.params.id);
  logAction(req.session.user.username, 'CHANGE_PASSWORD', null, req.params.id, { username: a?.username }, req.ip);
  req.flash('success', `Password updated for "${a?.username}".`);
  res.redirect('/settings/system');
});

router.post('/admin/:id/delete', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: a } = await sb.from('vv_admin_users').select('username').eq('id', req.params.id).single();
  if (a?.username === req.session.user.username) { req.flash('error', 'Cannot delete your own account.'); return res.redirect('/settings/system'); }
  await sb.from('vv_admin_users').delete().eq('id', req.params.id);
  logAction(req.session.user.username, 'DELETE_ADMIN_USER', null, req.params.id, { username: a?.username }, req.ip);
  req.flash('success', `Admin "${a?.username}" deleted.`);
  res.redirect('/settings/system');
});

router.post('/categories/add', requireAuth, async (req, res) => {
  const { name, icon } = req.body;
  const sb = getClient();
  await sb.from('vv_categories').insert({ name, icon: icon || 'tag', active: 1 });
  logAction(req.session.user.username, 'ADD_CATEGORY', null, null, { name }, req.ip);
  req.flash('success', `Category "${name}" added.`);
  res.redirect('/settings/categories');
});

router.post('/categories/:id/toggle', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: c } = await sb.from('vv_categories').select('*').eq('id', req.params.id).single();
  await sb.from('vv_categories').update({ active: c?.active ? 0 : 1 }).eq('id', req.params.id);
  req.flash('success', `Category "${c?.name}" ${c?.active ? 'deactivated' : 'activated'}.`);
  res.redirect('/settings/categories');
});

router.post('/cities/add', requireAuth, async (req, res) => {
  const { name } = req.body;
  const sb = getClient();
  await sb.from('vv_cities').insert({ name, active: 1 });
  logAction(req.session.user.username, 'ADD_CITY', null, null, { name }, req.ip);
  req.flash('success', `City "${name}" added.`);
  res.redirect('/settings/cities');
});

router.post('/cities/:id/toggle', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: c } = await sb.from('vv_cities').select('*').eq('id', req.params.id).single();
  await sb.from('vv_cities').update({ active: c?.active ? 0 : 1 }).eq('id', req.params.id);
  req.flash('success', `City "${c?.name}" ${c?.active ? 'deactivated' : 'activated'}.`);
  res.redirect('/settings/cities');
});

router.post('/demo/toggle', requireAuth, async (req, res) => {
  try {
    const sb = getClient();
    const { data } = await sb.from('vv_settings').select('value').eq('key', 'demo_data_enabled').single();
    const newVal = data?.value === '1' ? '0' : '1';
    await sb.from('vv_settings').upsert({ key: 'demo_data_enabled', value: newVal, updated_at: Math.floor(Date.now()/1000) });
    logAction(req.session.user.username, 'TOGGLE_DEMO_DATA', 'vv_settings', null, { demo_data_enabled: newVal }, req.ip);
    req.flash('success', `Demo data ${newVal === '1' ? 'enabled' : 'disabled'}.`);
  } catch (err) { req.flash('error', err.message); }
  res.redirect('/settings/system');
});

router.post('/regions/add', requireAuth, async (req, res) => {
  const { city_id, name, areas } = req.body;
  const sb = getClient();
  await sb.from('vv_regions').insert({ city_id, name, areas: areas || null, active: 1 });
  logAction(req.session.user.username, 'ADD_REGION', null, null, { city_id, name }, req.ip);
  req.flash('success', `Region "${name}" added.`);
  res.redirect('/settings/cities');
});

module.exports = router;
