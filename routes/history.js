const express = require('express');
const router  = express.Router();
const { getClient } = require('../db/connection');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, async (req, res) => {
  const { action, admin, from, to, page = 1 } = req.query;
  const limit = 30, offset = (page - 1) * limit;
  try {
    const sb = getClient();
    let q = sb.from('vv_admin_audit_log').select('*', { count: 'exact' });
    if (action) q = q.eq('action', action);
    if (admin)  q = q.eq('admin_username', admin);
    if (from)   q = q.gte('created_at', Math.floor(new Date(from).getTime() / 1000));
    if (to)     q = q.lte('created_at', Math.floor(new Date(to).getTime() / 1000) + 86400);
    q = q.order('created_at', { ascending: false }).range(offset, offset + limit - 1);
    const { data, count, error } = await q;
    if (error) throw new Error(error.message);

    const [{ data: admins }, { data: actions }] = await Promise.all([
      sb.from('vv_admin_audit_log').select('admin_username').order('admin_username'),
      sb.from('vv_admin_audit_log').select('action').order('action'),
    ]);
    const uniqueAdmins  = [...new Set((admins  || []).map(r => r.admin_username))].map(a => ({ admin_username: a }));
    const uniqueActions = [...new Set((actions || []).map(r => r.action))].map(a => ({ action: a }));

    res.render('history', {
      title: 'Activity History', logs: data || [],
      admins: uniqueAdmins, actions: uniqueActions,
      filters: { action, admin, from, to },
      pagination: { page: Number(page), limit, total: count || 0, pages: Math.ceil((count || 0) / limit) },
    });
  } catch (err) {
    req.flash('error', err.message);
    res.render('history', { title: 'Activity History', logs: [], admins: [], actions: [], filters: {}, pagination: { page: 1, pages: 1, total: 0, limit: 30 } });
  }
});

module.exports = router;
