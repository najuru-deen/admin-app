const express = require('express');
const session = require('express-session');
const flash   = require('connect-flash');
const ejsLayouts = require('express-ejs-layouts');
const path = require('path');

// Bootstrap DB connection on startup
const db = require('./db/connection');
const connectResult = db.connect();
if (connectResult.success) {
  console.log(`✓ Supabase client initialised`);
} else {
  console.warn(`⚠  DB not configured — open http://localhost:${db.getConfig().port || 4001}/settings`);
}

const config = db.getConfig();
const app = express();

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(ejsLayouts);
app.set('layout', 'layout');

// Static files
app.use(express.static(path.join(__dirname, 'public')));
// Also serve the main server's uploads folder for vendor media preview
const uploadsPath = path.join(__dirname, '../server/uploads');
app.use('/uploads', express.static(uploadsPath));

// Body parsing
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Sessions
app.use(session({
  secret: config.session_secret || 'vv-admin-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 8 * 60 * 60 * 1000 }, // 8 hours
}));

// Flash messages
app.use(flash());

// Global template locals
app.use((req, res, next) => {
  res.locals.user        = req.session.user || null;
  res.locals.success     = req.flash('success');
  res.locals.error       = req.flash('error');
  res.locals.currentPath = req.path;
  res.locals.dbError     = db.getConfigError();
  next();
});

// Routes
app.use('/',            require('./routes/auth'));
app.use('/login',       require('./routes/auth'));
app.use('/',            require('./routes/dashboard'));
app.use('/vendors',     require('./routes/vendors'));
app.use('/subscribers', require('./routes/subscribers'));
app.use('/settings',    require('./routes/settings'));
app.use('/api',         require('./routes/settings'));  // public settings API at /api/settings
app.use('/history',     require('./routes/history'));

// 404
app.use((req, res) => {
  res.status(404).render('404', { title: 'Page Not Found' });
});

// Multer / upload error handler
app.use((err, req, res, next) => {
  if (err?.code === 'LIMIT_FILE_SIZE') {
    req.flash('error', 'File too large. Maximum size is 5MB per image.');
    return res.redirect('back');
  }
  if (err?.code === 'LIMIT_FILE_COUNT') {
    req.flash('error', 'Too many files. Maximum 5 images allowed.');
    return res.redirect('back');
  }
  if (err?.message?.includes('Only image files')) {
    req.flash('error', err.message);
    return res.redirect('back');
  }
  console.error(err);
  res.status(500).render('error', { title: 'Server Error', message: err.message });
});

const PORT = config.port || 4000;
const server = app.listen(PORT, () => {
  console.log(`\n🚀 VV Admin App running at http://localhost:${PORT}`);
  console.log(`   Login with: admin / admin123\n`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`\n❌ Port ${PORT} is already in use.`);
    console.error(`   Either stop the other process, or change "port" in admin-app/data/config.json\n`);
  } else {
    console.error('Server error:', err.message);
  }
  process.exit(1);
});
