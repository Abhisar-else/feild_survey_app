// ── Field Survey App — Backend Server ────────────────────────
// Express.js REST API with MySQL

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const surveyRoutes = require('./routes/surveys');
const responseRoutes = require('./routes/responses');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// ── Routes ───────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/surveys', surveyRoutes);
app.use('/api/responses', responseRoutes);

// ── Health Check ─────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🚀 Field Survey API is running!',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth/login, /api/auth/register',
      surveys: '/api/surveys',
      responses: '/api/responses',
      export: '/api/responses/export',
    },
  });
});

// ── 404 Handler ──────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found.`,
  });
});

// ── Global Error Handler ─────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error.',
  });
});

// ── Start Server ─────────────────────────────────────────────
app.listen(PORT, () => {
  console.log('');
  console.log('═══════════════════════════════════════════════');
  console.log(`  🚀 Field Survey API Server`);
  console.log(`  📡 Running on http://localhost:${PORT}`);
  console.log(`  📋 Health check: http://localhost:${PORT}/`);
  console.log('═══════════════════════════════════════════════');
  console.log('');
});

module.exports = app;
