require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');

const app = express();
const PORT = process.env.PORT || 5000;
const APP_API_SECRET = process.env.APP_API_SECRET || 'salon_sec_9a87d6f5e4c3b2a1';

// Middlewares
app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Public health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    appName: 'Salon Appointment Booking Backend',
    timezone: 'Asia/Karachi',
    timestamp: new Date().toISOString()
  });
});

// Root welcome
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Salon Appointment Booking API is running.',
    health: '/health'
  });
});

// Anti-Bot / App Secret Authentication Middleware
app.use((req, res, next) => {
  // Allow health and root
  if (req.path === '/' || req.path === '/health') {
    return next();
  }

  const providedSecret = req.headers['x-app-secret'] || req.query.secret;
  if (!providedSecret || providedSecret !== APP_API_SECRET) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Missing or invalid X-App-Secret header.'
    });
  }
  next();
});

// Protected Routes
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('[ServerError]', err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

// Start HTTP server if run directly (local / non-Vercel)
if (process.env.VERCEL !== '1' && require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`  Salon Appointment Booking Backend listening on port ${PORT}`);
    console.log(`  Timezone: Asia/Karachi (PKT, UTC+5)`);
    console.log(`  Health Check: http://localhost:${PORT}/health`);
    console.log(`======================================================\n`);
  });
}

module.exports = app;
