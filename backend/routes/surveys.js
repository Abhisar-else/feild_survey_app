// ── Survey Routes ────────────────────────────────────────────
const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const {
  getAllSurveys,
  getSurveyById,
  createSurvey,
  updateSurvey,
  deleteSurvey,
} = require('../controllers/surveyController');

// All survey routes require authentication
router.use(authenticate);

// GET /api/surveys        — List all surveys
router.get('/', getAllSurveys);

// GET /api/surveys/:id    — Get survey with questions
router.get('/:id', getSurveyById);

// POST /api/surveys       — Create survey (admin only)
router.post('/', requireAdmin, createSurvey);

// PUT /api/surveys/:id    — Update survey (admin only)
router.put('/:id', requireAdmin, updateSurvey);

// DELETE /api/surveys/:id — Delete survey (admin only)
router.delete('/:id', requireAdmin, deleteSurvey);

module.exports = router;
