// ── Response Controller ──────────────────────────────────────
// Handles survey response submission, retrieval, and CSV export.

const pool = require('../config/db');

/**
 * POST /api/responses
 * Body: { survey_id, answers, latitude?, longitude?, device_id?, created_at? }
 * Also supports batch: { responses: [{ survey_id, answers, ... }] }
 */
async function submitResponse(req, res) {
  try {
    const userId = req.user.id;

    // Support batch sync
    if (req.body.responses && Array.isArray(req.body.responses)) {
      return submitBatchResponses(req, res);
    }

    const { survey_id, answers, latitude, longitude, device_id, created_at } = req.body;

    // Validate
    if (!survey_id) {
      return res.status(400).json({
        success: false,
        message: 'survey_id is required.',
      });
    }

    // Verify survey exists
    const [surveys] = await pool.query('SELECT id FROM surveys WHERE id = ?', [survey_id]);
    if (surveys.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Survey not found.',
      });
    }

    const answersJson = typeof answers === 'string' ? answers : JSON.stringify(answers || {});

    const [result] = await pool.query(
      `INSERT INTO responses (survey_id, user_id, answers, latitude, longitude, device_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        survey_id,
        userId,
        answersJson,
        latitude || null,
        longitude || null,
        device_id || null,
        created_at || new Date(),
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Response submitted successfully.',
      data: {
        id: result.insertId,
        survey_id,
        user_id: userId,
        synced_at: new Date(),
      },
    });
  } catch (error) {
    console.error('Submit response error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

/**
 * Handles batch response submission for offline sync.
 */
async function submitBatchResponses(req, res) {
  const connection = await pool.getConnection();
  try {
    const userId = req.user.id;
    const { responses: batchResponses } = req.body;

    await connection.beginTransaction();

    const results = [];
    for (const entry of batchResponses) {
      const answersJson =
        typeof entry.answers === 'string'
          ? entry.answers
          : JSON.stringify(entry.answers || {});

      const [result] = await connection.query(
        `INSERT INTO responses (survey_id, user_id, answers, latitude, longitude, device_id, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          entry.survey_id,
          userId,
          answersJson,
          entry.latitude || null,
          entry.longitude || null,
          entry.device_id || null,
          entry.created_at || new Date(),
        ]
      );

      results.push({
        id: result.insertId,
        survey_id: entry.survey_id,
        synced: true,
      });
    }

    await connection.commit();

    res.status(201).json({
      success: true,
      message: `${results.length} responses synced successfully.`,
      data: results,
    });
  } catch (error) {
    await connection.rollback();
    console.error('Batch submit error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  } finally {
    connection.release();
  }
}

/**
 * GET /api/responses
 * Query params: ?survey_id=1&page=1&limit=50
 * Admin: all responses. Field worker: own responses only.
 */
async function getAllResponses(req, res) {
  try {
    const { survey_id, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let query = `
      SELECT 
        r.*,
        s.title AS survey_title,
        u.name AS user_name,
        u.email AS user_email
      FROM responses r
      LEFT JOIN surveys s ON r.survey_id = s.id
      LEFT JOIN users u ON r.user_id = u.id
    `;

    const conditions = [];
    const params = [];

    // If not admin, only show own responses
    if (req.user.role !== 'admin') {
      conditions.push('r.user_id = ?');
      params.push(req.user.id);
    }

    // Filter by survey
    if (survey_id) {
      conditions.push('r.survey_id = ?');
      params.push(parseInt(survey_id));
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ' ORDER BY r.created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [responses] = await pool.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) AS total FROM responses r';
    const countParams = [];

    const countConditions = [];
    if (req.user.role !== 'admin') {
      countConditions.push('r.user_id = ?');
      countParams.push(req.user.id);
    }
    if (survey_id) {
      countConditions.push('r.survey_id = ?');
      countParams.push(parseInt(survey_id));
    }
    if (countConditions.length > 0) {
      countQuery += ' WHERE ' + countConditions.join(' AND ');
    }

    const [countResult] = await pool.query(countQuery, countParams);

    res.json({
      success: true,
      data: responses,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: countResult[0].total,
        totalPages: Math.ceil(countResult[0].total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Get responses error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

/**
 * GET /api/responses/export
 * Query params: ?survey_id=1
 * Exports responses as CSV file download.
 */
async function exportResponses(req, res) {
  try {
    const { survey_id } = req.query;

    let query = `
      SELECT 
        r.id,
        s.title AS survey_title,
        u.name AS user_name,
        u.email AS user_email,
        r.answers,
        r.latitude,
        r.longitude,
        r.device_id,
        r.synced_at,
        r.created_at
      FROM responses r
      LEFT JOIN surveys s ON r.survey_id = s.id
      LEFT JOIN users u ON r.user_id = u.id
    `;

    const params = [];
    if (survey_id) {
      query += ' WHERE r.survey_id = ?';
      params.push(parseInt(survey_id));
    }

    query += ' ORDER BY r.created_at DESC';

    const [responses] = await pool.query(query, params);

    if (responses.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No responses found to export.',
      });
    }

    // Flatten answers JSON for CSV
    const flatData = responses.map((row) => {
      let parsedAnswers = {};
      try {
        parsedAnswers =
          typeof row.answers === 'string' ? JSON.parse(row.answers) : row.answers || {};
      } catch (e) {
        parsedAnswers = {};
      }

      return {
        id: row.id,
        survey_title: row.survey_title,
        user_name: row.user_name,
        user_email: row.user_email,
        answers: JSON.stringify(parsedAnswers),
        latitude: row.latitude,
        longitude: row.longitude,
        device_id: row.device_id,
        synced_at: row.synced_at,
        created_at: row.created_at,
      };
    });

    // Use json2csv
    const { Parser } = require('json2csv');
    const fields = [
      'id',
      'survey_title',
      'user_name',
      'user_email',
      'answers',
      'latitude',
      'longitude',
      'device_id',
      'synced_at',
      'created_at',
    ];
    const csvParser = new Parser({ fields });
    const csv = csvParser.parse(flatData);

    const filename = survey_id
      ? `responses_survey_${survey_id}.csv`
      : 'responses_all.csv';

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(csv);
  } catch (error) {
    console.error('Export responses error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

module.exports = {
  submitResponse,
  getAllResponses,
  exportResponses,
};
