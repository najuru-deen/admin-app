const express = require('express');
const router  = express.Router();
const { getClient, logAction } = require('../db/connection');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, async (req, res) => {
  const { tier, payment_status, search, page = 1 } = req.query;
  const limit = 20, offset = (page - 1) * limit;
  const now = Math.floor(Date.now() / 1000);
  try {
    const sb = getClient();
    let q = sb.from('vv_memberships')
      .select('*, vendor:vv_vendors(name, mobile, status, category:vv_categories(name), city:vv_cities(name))', { count: 'exact' });
    if (tier)           q = q.eq('tier', tier);
    if (payment_status) q = q.eq('payment_status', payment_status);
    q = q.order('created_at', { ascending: false }).range(offset, offset + limit - 1);
    const { data, count, error } = await q;
    if (error) throw new Error(error.message);

    const memberships = (data || []).map(m => ({
      ...m,
      vendor_name:   m.vendor?.name,
      vendor_mobile: m.vendor?.mobile,
      vendor_status: m.vendor?.status,
      category_name: m.vendor?.category?.name,
      city_name:     m.vendor?.city?.name,
      vendor: undefined,
    }));

    const [
      { count: total }, { count: paid }, { count: active }, { data: paidRows },
    ] = await Promise.all([
      sb.from('vv_memberships').select('*', { count: 'exact', head: true }),
      sb.from('vv_memberships').select('*', { count: 'exact', head: true }).eq('payment_status', 'paid'),
      sb.from('vv_memberships').select('*', { count: 'exact', head: true }).gt('expires_at', now),
      sb.from('vv_memberships').select('amount').eq('payment_status', 'paid'),
    ]);
    const revenue = (paidRows || []).reduce((s, r) => s + (Number(r.amount) || 0), 0);

    res.render('subscribers', {
      title: 'Subscribers & Memberships', memberships,
      stats: { total: total || 0, paid: paid || 0, active: active || 0, revenue },
      filters: { tier, payment_status, search }, now,
      pagination: { page: Number(page), limit, total: count || 0, pages: Math.ceil((count || 0) / limit) },
    });
  } catch (err) {
    req.flash('error', err.message);
    res.render('subscribers', { title: 'Subscribers & Memberships', memberships: [], stats: {}, filters: {}, now, pagination: { page: 1, pages: 1, total: 0, limit: 20 } });
  }
});

router.post('/add', requireAuth, async (req, res) => {
  const { vendor_id, tier, amount, payment_status } = req.body;
  if (!vendor_id || !tier) { req.flash('error', 'Vendor and tier are required.'); return res.redirect('/subscribers'); }
  const sb = getClient();
  const { data: vendor } = await sb.from('vv_vendors').select('name').eq('id', vendor_id).single();
  if (!vendor) { req.flash('error', 'Vendor not found.'); return res.redirect('/subscribers'); }
  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + 365 * 86400;
  const tierAmounts = { basic: 0, silver: 2000, gold: 5000, platinum: 25000 };
  const finalAmount = Number(amount) || tierAmounts[tier] || 0;
  const payRef = 'PAY-' + Math.random().toString(36).substring(2, 10).toUpperCase();
  await sb.from('vv_memberships').insert({ vendor_id, tier, amount: finalAmount, payment_status: payment_status || 'paid', payment_ref: payRef, expires_at: expiresAt, created_at: now });
  await sb.from('vv_vendors').update({ membership_tier: tier, subscription_expires: expiresAt }).eq('id', vendor_id);
  logAction(req.session.user.username, 'ADD_MEMBERSHIP', 'vv_memberships', null, { vendor_id, tier }, req.ip);
  req.flash('success', `Membership (${tier}) added for "${vendor.name}".`);
  res.redirect('/subscribers');
});

router.post('/:id/mark-paid', requireAuth, async (req, res) => {
  const sb = getClient();
  await sb.from('vv_memberships').update({ payment_status: 'paid' }).eq('id', req.params.id);
  logAction(req.session.user.username, 'MARK_PAID', 'vv_memberships', req.params.id, null, req.ip);
  req.flash('success', 'Marked as paid.');
  res.redirect('/subscribers');
});

router.post('/:id/extend', requireAuth, async (req, res) => {
  const { days } = req.body;
  const sb = getClient();
  const { data: m } = await sb.from('vv_memberships').select('*').eq('id', req.params.id).single();
  if (!m) { req.flash('error', 'Not found.'); return res.redirect('/subscribers'); }
  const now = Math.floor(Date.now() / 1000);
  const newExpiry = (Number(m.expires_at) || now) + (Number(days) || 365) * 86400;
  await sb.from('vv_memberships').update({ expires_at: newExpiry }).eq('id', req.params.id);
  await sb.from('vv_vendors').update({ subscription_expires: newExpiry }).eq('id', m.vendor_id);
  logAction(req.session.user.username, 'EXTEND_MEMBERSHIP', 'vv_memberships', req.params.id, { days }, req.ip);
  req.flash('success', `Extended by ${days || 365} days.`);
  res.redirect('/subscribers');
});

router.post('/:id/delete', requireAuth, async (req, res) => {
  const sb = getClient();
  const { data: m } = await sb.from('vv_memberships').select('tier, vendor_id').eq('id', req.params.id).single();
  await sb.from('vv_memberships').delete().eq('id', req.params.id);
  logAction(req.session.user.username, 'DELETE_MEMBERSHIP', 'vv_memberships', req.params.id, { tier: m?.tier }, req.ip);
  req.flash('success', 'Membership deleted.');
  res.redirect('/subscribers');
});

module.exports = router;
