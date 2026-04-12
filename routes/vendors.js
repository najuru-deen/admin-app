const express = require('express');
const router  = express.Router();
const { getClient, logAction } = require('../db/connection');
const { requireAuth } = require('../middleware/auth');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const uploadDir = path.join(__dirname, '../../server/uploads/vendors');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename:    (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, `v_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (/^image\/(jpeg|jpg|png|webp|gif)$/i.test(file.mimetype)) cb(null, true);
    else cb(new Error('Only image files are allowed (jpg, png, webp, gif)'));
  },
});

function flatVendor(v) {
  if (!v) return null;
  return {
    ...v,
    category_name: v.category?.name,
    city_name:     v.city?.name,
    region_name:   v.region?.name,
    category: undefined, city: undefined, region: undefined,
  };
}

router.get('/', requireAuth, async (req, res) => {
  const { status, tier, city, category, search, page = 1 } = req.query;
  const limit = 20, offset = (page - 1) * limit;
  try {
    const sb = getClient();
    let q = sb.from('vv_vendors')
      .select('*, category:vv_categories(name), city:vv_cities(name)', { count: 'exact' });
    if (status)   q = q.eq('status', status);
    if (tier)     q = q.eq('membership_tier', tier);
    if (city)     q = q.eq('city_id', city);
    if (category) q = q.eq('category_id', category);
    if (search)   q = q.or(`name.ilike.%${search}%,mobile.ilike.%${search}%`);
    q = q.order('created_at', { ascending: false }).range(offset, offset + limit - 1);
    const { data, count, error } = await q;
    if (error) throw new Error(error.message);
    const [{ data: categories }, { data: cities }] = await Promise.all([
      sb.from('vv_categories').select('*').order('name'),
      sb.from('vv_cities').select('*').order('name'),
    ]);
    res.render('vendors', {
      title: 'All Vendors', vendors: (data || []).map(flatVendor),
      categories: categories || [], cities: cities || [],
      filters: { status, tier, city, category, search },
      pagination: { page: Number(page), limit, total: count || 0, pages: Math.ceil((count || 0) / limit) },
    });
  } catch (err) {
    req.flash('error', err.message);
    res.render('vendors', { title: 'All Vendors', vendors: [], categories: [], cities: [], filters: {}, pagination: { page: 1, pages: 1, total: 0, limit: 20 } });
  }
});

router.get('/pending', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data, error } = await sb.from('vv_vendors')
    .select('*, category:vv_categories(name), city:vv_cities(name)')
    .eq('status', 'pending').order('created_at', { ascending: true });
  if (error) req.flash('error', error.message);
  res.render('pending-vendors', { title: 'Pending Approval', vendors: (data || []).map(flatVendor) });
});

router.get('/add', requireAuth, async (req, res) => {
  const sb = getClient();
  const [{ data: categories }, { data: cities }, { data: regions }] = await Promise.all([
    sb.from('vv_categories').select('*').eq('active', 1).order('name'),
    sb.from('vv_cities').select('*').eq('active', 1).order('name'),
    sb.from('vv_regions').select('*').order('name'),
  ]);
  res.render('add-vendor', { title: 'Add Vendor', categories: categories || [], cities: cities || [], regions: regions || [] });
});

router.post('/add', requireAuth, upload.array('photos', 5), async (req, res) => {
  const { name, full_address, mobile, whatsapp, category_id, city_id,
    region_id, membership_tier, description, amount, status,
    is_verified, is_trusted, is_trending, photo_urls } = req.body;
  if (!name || !mobile || !category_id || !city_id) {
    req.flash('error', 'Name, mobile, category, and city are required.');
    return res.redirect('/vendors/add');
  }
  try {
    const sb = getClient();
    const { data, error } = await sb.from('vv_vendors').insert({
      name, full_address: full_address || null, mobile, whatsapp: whatsapp || null,
      category_id: Number(category_id), city_id: Number(city_id),
      region_id: region_id ? Number(region_id) : null,
      membership_tier: membership_tier || 'basic',
      description: description || null, amount: amount || null,
      status: status || 'pending',
      is_verified: is_verified ? 1 : 0, is_trusted: is_trusted ? 1 : 0, is_trending: is_trending ? 1 : 0,
      created_at: Math.floor(Date.now() / 1000),
    }).select('id').single();
    if (error) throw new Error(error.message);
    // Insert uploaded files + any photo URLs
    const ts = Math.floor(Date.now() / 1000);
    const mediaRows = [];
    if (req.files?.length) {
      req.files.forEach(f => mediaRows.push({ vendor_id: data.id, type: 'image', url: `/uploads/vendors/${f.filename}`, created_at: ts }));
    }
    if (photo_urls) {
      const urls = (Array.isArray(photo_urls) ? photo_urls : [photo_urls]).map(u => u.trim()).filter(Boolean);
      urls.forEach(url => mediaRows.push({ vendor_id: data.id, type: 'image', url, created_at: ts }));
    }
    if (mediaRows.length) await sb.from('vv_vendor_media').insert(mediaRows);
    logAction(req.session.user.username, 'ADD_VENDOR', 'vv_vendors', data.id, { name }, req.ip);
    req.flash('success', `Vendor "${name}" added.`);
    res.redirect(`/vendors/${data.id}`);
  } catch (err) {
    req.flash('error', `Error: ${err.message}`);
    res.redirect('/vendors/add');
  }
});

router.get('/:id', requireAuth, async (req, res) => {
  try {
    const sb = getClient();
    const [
      { data: vendor, error: ve },
      { data: media }, { data: memberships }, { data: leads },
      { data: categories }, { data: cities }, { data: regions },
    ] = await Promise.all([
      sb.from('vv_vendors').select('*, category:vv_categories(name), city:vv_cities(name), region:vv_regions(name)').eq('id', req.params.id).single(),
      sb.from('vv_vendor_media').select('*').eq('vendor_id', req.params.id).order('created_at', { ascending: false }),
      sb.from('vv_memberships').select('*').eq('vendor_id', req.params.id).order('created_at', { ascending: false }),
      sb.from('vv_leads').select('*').eq('vendor_id', req.params.id).order('created_at', { ascending: false }).limit(20),
      sb.from('vv_categories').select('*').order('name'),
      sb.from('vv_cities').select('*').order('name'),
      sb.from('vv_regions').select('*').order('name'),
    ]);
    if (ve || !vendor) { req.flash('error', 'Vendor not found.'); return res.redirect('/vendors'); }
    res.render('vendor-detail', {
      title: vendor.name, vendor: flatVendor(vendor),
      media: media || [], memberships: memberships || [], leads: leads || [],
      categories: categories || [], cities: cities || [], regions: regions || [],
    });
  } catch (err) { req.flash('error', err.message); res.redirect('/vendors'); }
});

router.post('/:id/update', requireAuth, async (req, res) => {
  const { name, full_address, mobile, whatsapp, category_id, city_id,
    region_id, membership_tier, description, amount, status,
    is_verified, is_trusted, is_trending, latitude, longitude } = req.body;
  try {
    const sb = getClient();
    const { error } = await sb.from('vv_vendors').update({
      name, full_address: full_address || null, mobile, whatsapp: whatsapp || null,
      category_id: Number(category_id), city_id: Number(city_id),
      region_id: region_id ? Number(region_id) : null,
      membership_tier, description: description || null, amount: amount || null, status,
      is_verified: is_verified ? 1 : 0, is_trusted: is_trusted ? 1 : 0, is_trending: is_trending ? 1 : 0,
      latitude: latitude ? Number(latitude) : null, longitude: longitude ? Number(longitude) : null,
    }).eq('id', req.params.id);
    if (error) throw new Error(error.message);
    logAction(req.session.user.username, 'UPDATE_VENDOR', 'vv_vendors', req.params.id, { name, status, membership_tier }, req.ip);
    req.flash('success', 'Vendor updated.');
  } catch (err) { req.flash('error', `Update failed: ${err.message}`); }
  res.redirect(`/vendors/${req.params.id}`);
});

router.post('/:id/approve', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: v } = await sb.from('vv_vendors').select('name').eq('id', req.params.id).single();
  const { error } = await sb.from('vv_vendors').update({ status: 'approved' }).eq('id', req.params.id);
  if (error) req.flash('error', error.message);
  else {
    logAction(req.session.user.username, 'APPROVE_VENDOR', 'vv_vendors', req.params.id, { name: v?.name }, req.ip);
    req.flash('success', `Vendor "${v?.name}" approved.`);
  }
  res.redirect(`/vendors/${req.params.id}`);
});

router.post('/:id/reject', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: v } = await sb.from('vv_vendors').select('name').eq('id', req.params.id).single();
  const { error } = await sb.from('vv_vendors').update({ status: 'rejected' }).eq('id', req.params.id);
  if (error) req.flash('error', error.message);
  else {
    logAction(req.session.user.username, 'REJECT_VENDOR', 'vv_vendors', req.params.id, { name: v?.name }, req.ip);
    req.flash('success', `Vendor "${v?.name}" rejected.`);
  }
  res.redirect(`/vendors/${req.params.id}`);
});

router.post('/:id/delete', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: v } = await sb.from('vv_vendors').select('name').eq('id', req.params.id).single();
  await sb.from('vv_vendor_media').delete().eq('vendor_id', req.params.id);
  await sb.from('vv_leads').delete().eq('vendor_id', req.params.id);
  await sb.from('vv_memberships').delete().eq('vendor_id', req.params.id);
  const { error } = await sb.from('vv_vendors').delete().eq('id', req.params.id);
  if (error) { req.flash('error', error.message); return res.redirect(`/vendors/${req.params.id}`); }
  logAction(req.session.user.username, 'DELETE_VENDOR', 'vv_vendors', req.params.id, { name: v?.name }, req.ip);
  req.flash('success', `Vendor "${v?.name}" deleted.`);
  res.redirect('/vendors');
});

router.post('/:id/media/add', requireAuth, upload.array('photos', 5), async (req, res) => {
  const { url } = req.body;
  try {
    const sb = getClient();
    const ts = Math.floor(Date.now() / 1000);
    const rows = [];
    if (req.files?.length) {
      req.files.forEach(f => rows.push({ vendor_id: Number(req.params.id), type: 'image', url: `/uploads/vendors/${f.filename}`, created_at: ts }));
    }
    if (url?.trim()) {
      rows.push({ vendor_id: Number(req.params.id), type: 'image', url: url.trim(), created_at: ts });
    }
    if (!rows.length) { req.flash('error', 'Select at least one image or enter a URL.'); return res.redirect(`/vendors/${req.params.id}`); }
    const { error } = await sb.from('vv_vendor_media').insert(rows);
    if (error) throw new Error(error.message);
    req.flash('success', `${rows.length} photo(s) added.`);
  } catch (err) {
    // remove uploaded files on DB error
    (req.files || []).forEach(f => fs.unlink(f.path, () => {}));
    req.flash('error', err.message);
  }
  res.redirect(`/vendors/${req.params.id}`);
});

router.post('/:id/media/:mid/delete', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: m } = await sb.from('vv_vendor_media').select('url').eq('id', req.params.mid).single();
  const { error } = await sb.from('vv_vendor_media').delete()
    .eq('id', req.params.mid).eq('vendor_id', req.params.id);
  if (error) { req.flash('error', error.message); }
  else {
    // delete local file if it's an upload
    if (m?.url?.startsWith('/uploads/vendors/')) {
      const filePath = path.join(uploadDir, path.basename(m.url));
      fs.unlink(filePath, () => {});
    }
    req.flash('success', 'Photo deleted.');
  }
  res.redirect(`/vendors/${req.params.id}`);
});

router.post('/:id/membership', requireAuth, async (req, res) => {
  const { tier, amount, payment_status, payment_ref, expires_at } = req.body;
  try {
    const sb = getClient();
    const expiresTs = expires_at ? Math.floor(new Date(expires_at).getTime() / 1000) : null;
    const { error: me } = await sb.from('vv_memberships').insert({
      vendor_id: Number(req.params.id), tier, amount: Number(amount) || 0,
      payment_status: payment_status || 'pending', payment_ref: payment_ref || null,
      created_at: Math.floor(Date.now() / 1000), expires_at: expiresTs,
    });
    if (me) throw new Error(me.message);
    const { error: ve } = await sb.from('vv_vendors').update({
      membership_tier: tier, subscription_expires: expiresTs,
    }).eq('id', req.params.id);
    if (ve) throw new Error(ve.message);
    logAction(req.session.user.username, 'ADD_MEMBERSHIP', 'vv_memberships', req.params.id, { tier, amount, payment_status }, req.ip);
    req.flash('success', `Membership (${tier}) recorded.`);
  } catch (err) { req.flash('error', err.message); }
  res.redirect(`/vendors/${req.params.id}`);
});

module.exports = router;
