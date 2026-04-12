const express = require('express');
const router  = express.Router();
const { getClient, flattenAll } = require('../db/connection');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, async (req, res) => {
  try {
    const sb  = getClient();
    const now = Math.floor(Date.now() / 1000);
    const todayStart = Math.floor(new Date().setHours(0, 0, 0, 0) / 1000);

    const [
      { count: totalVendors },
      { count: pendingVendors },
      { count: approvedVendors },
      { count: rejectedVendors },
      { count: activeSubscribers },
      { count: leadsToday },
      { count: totalLeads },
      { data: paidMemberships },
      { data: tierRows },
      { data: recentVendorsRaw },
      { data: recentLeadsRaw },
    ] = await Promise.all([
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }),
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }).eq('status', 'approved'),
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }).eq('status', 'rejected'),
      sb.from('vv_vendors').select('*', { count: 'exact', head: true }).gt('subscription_expires', now),
      sb.from('vv_leads').select('*', { count: 'exact', head: true }).gte('created_at', todayStart),
      sb.from('vv_leads').select('*', { count: 'exact', head: true }),
      sb.from('vv_memberships').select('amount').eq('payment_status', 'paid'),
      sb.from('vv_vendors').select('membership_tier').eq('status', 'approved'),
      sb.from('vv_vendors')
        .select('*, category:vv_categories(name), city:vv_cities(name)')
        .order('created_at', { ascending: false })
        .limit(8),
      sb.from('vv_leads')
        .select('*, vendor:vv_vendors(name, category:vv_categories(name))')
        .order('created_at', { ascending: false })
        .limit(5),
    ]);

    const revenue = (paidMemberships || []).reduce((s, m) => s + (Number(m.amount) || 0), 0);

    const tierMap = {};
    for (const r of (tierRows || [])) {
      tierMap[r.membership_tier] = (tierMap[r.membership_tier] || 0) + 1;
    }

    // Flatten nested relations → category_name, city_name etc.
    const recentVendors = (recentVendorsRaw || []).map(v => ({
      ...v,
      category_name: v.category?.name,
      city_name:     v.city?.name,
      category: undefined, city: undefined,
    }));

    const recentLeads = (recentLeadsRaw || []).map(l => ({
      ...l,
      vendor_name:   l.vendor?.name,
      category_name: l.vendor?.category?.name,
      vendor: undefined,
    }));

    res.render('dashboard', {
      title: 'Dashboard',
      stats: {
        totalVendors:     totalVendors    || 0,
        pendingVendors:   pendingVendors  || 0,
        approvedVendors:  approvedVendors || 0,
        rejectedVendors:  rejectedVendors || 0,
        activeSubscribers: activeSubscribers || 0,
        leadsToday:       leadsToday      || 0,
        totalLeads:       totalLeads      || 0,
        revenue:          revenue.toLocaleString('en-IN'),
      },
      tierBreakdown: {
        basic:    tierMap['basic']    || 0,
        silver:   tierMap['silver']   || 0,
        gold:     tierMap['gold']     || 0,
        platinum: tierMap['platinum'] || 0,
      },
      recentVendors,
      recentLeads,
    });
  } catch (err) {
    console.error('Dashboard error:', err.message);
    res.render('dashboard', {
      title: 'Dashboard', stats: {}, tierBreakdown: {},
      recentVendors: [], recentLeads: [], dbError: err.message,
    });
  }
});

module.exports = router;
