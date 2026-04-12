const express = require('express');
const router  = express.Router();
const { getClient, logAction, getConfigError } = require('../db/connection');
const { redirectIfAuth } = require('../middleware/auth');

router.get('/login', redirectIfAuth, (req, res) => {
  res.render('login', { title: 'Admin Login', layout: false, dbError: getConfigError() });
});

router.post('/login', redirectIfAuth, async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    req.flash('error', 'Username and password are required.');
    return res.redirect('/login');
  }
  try {
    const sb = getClient();
    const { data, error } = await sb
      .from('vv_admin_users')
      .select('*')
      .eq('username', username)
      .single();

    if (error || !data || data.password !== password) {
      req.flash('error', 'Invalid username or password.');
      logAction(username, 'LOGIN_FAILED', null, null, { reason: 'invalid credentials' }, req.ip);
      return res.redirect('/login');
    }
    req.session.user = { id: data.id, username: data.username };
    logAction(data.username, 'LOGIN', null, data.id, null, req.ip);
    res.redirect('/');
  } catch (err) {
    req.flash('error', `Database error: ${err.message}`);
    res.redirect('/login');
  }
});

router.post('/logout', (req, res) => {
  const username = req.session.user?.username;
  req.session.destroy(() => {
    if (username) logAction(username, 'LOGOUT', null, null, null, req.ip);
    res.redirect('/login');
  });
});

module.exports = router;
