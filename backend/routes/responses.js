// ── Response Routes ──────────────────────────────────────────
const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const {
  submitResponse,
  getAllResponses,
  exportResponses,
} = require('../controllers/responseController');

// All response routes require authentication
router.use(authenticate);

// GET /api/responses/export — Export as CSV (admin only) — must be before /:id
router.get('/export', requireAdmin, exportResponses);

// GET /api/responses        — List responses (admin: all, worker: own)
router.get('/', getAllResponses);

// POST /api/responses       — Submit response (single or batch)
router.post('/', submitResponse);

module.exports = router;
