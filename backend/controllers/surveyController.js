// ── Survey Controller ────────────────────────────────────────
// Handles CRUD for surveys and their questions.

const pool = require('../config/db');

/**
 * GET /api/surveys
 * Returns all surveys with question count and response count.
 */
async function getAllSurveys(req, res) {
  try {
    const [surveys] = await pool.query(`
      SELECT 
        s.*,
        u.name AS creator_name,
        (SELECT COUNT(*) FROM questions q WHERE q.survey_id = s.id) AS question_count,
        (SELECT COUNT(*) FROM responses r WHERE r.survey_id = s.id) AS response_count
      FROM surveys s
      LEFT JOIN users u ON s.created_by = u.id
      ORDER BY s.created_at DESC
    `);

    res.json({
      success: true,
      data: surveys,
    });
  } catch (error) {
    console.error('Get surveys error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

/**
 * GET /api/surveys/:id
 * Returns a single survey with all its questions.
 */
async function getSurveyById(req, res) {
  try {
    const { id } = req.params;

    // Get survey
    const [surveys] = await pool.query(
      `SELECT s.*, u.name AS creator_name 
       FROM surveys s 
       LEFT JOIN users u ON s.created_by = u.id 
       WHERE s.id = ?`,
      [id]
    );

    if (surveys.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Survey not found.',
      });
    }

    // Get questions
    const [questions] = await pool.query(
      'SELECT * FROM questions WHERE survey_id = ? ORDER BY question_order ASC',
      [id]
    );

    // Get response count
    const [countResult] = await pool.query(
      'SELECT COUNT(*) AS response_count FROM responses WHERE survey_id = ?',
      [id]
    );

    res.json({
      success: true,
      data: {
        ...surveys[0],
        questions,
        response_count: countResult[0].response_count,
      },
    });
  } catch (error) {
    console.error('Get survey error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

/**
 * POST /api/surveys
 * Body: { title, description, questions: [{ text, type }] }
 * Creates a survey and its questions in a transaction.
 */
async function createSurvey(req, res) {
  const connection = await pool.getConnection();
  try {
    const { title, description, questions } = req.body;
    const createdBy = req.user.id;

    // Validate
    if (!title || !title.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Survey title is required.',
      });
    }

    await connection.beginTransaction();

    // Insert survey
    const [surveyResult] = await connection.query(
      'INSERT INTO surveys (title, description, created_by) VALUES (?, ?, ?)',
      [title.trim(), description || '', createdBy]
    );

    const surveyId = surveyResult.insertId;

    // Insert questions
    if (questions && questions.length > 0) {
      const questionValues = questions.map((q, index) => [
        surveyId,
        q.text || '',
        q.type || 'Text Input',
        index,
      ]);

      await connection.query(
        'INSERT INTO questions (survey_id, question_text, question_type, question_order) VALUES ?',
        [questionValues]
      );
    }

    await connection.commit();

    // Fetch the created survey with questions
    const [createdSurvey] = await pool.query(
      'SELECT * FROM surveys WHERE id = ?',
      [surveyId]
    );
    const [createdQuestions] = await pool.query(
      'SELECT * FROM questions WHERE survey_id = ? ORDER BY question_order ASC',
      [surveyId]
    );

    res.status(201).json({
      success: true,
      message: 'Survey created successfully.',
      data: {
        ...createdSurvey[0],
        questions: createdQuestions,
      },
    });
  } catch (error) {
    await connection.rollback();
    console.error('Create survey error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  } finally {
    connection.release();
  }
}

/**
 * PUT /api/surveys/:id
 * Body: { title, description, status, questions: [{ text, type }] }
 * Updates survey and replaces all questions.
 */
async function updateSurvey(req, res) {
  const connection = await pool.getConnection();
  try {
    const { id } = req.params;
    const { title, description, status, questions } = req.body;

    // Check survey exists
    const [existing] = await pool.query('SELECT id FROM surveys WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Survey not found.',
      });
    }

    await connection.beginTransaction();

    // Update survey
    await connection.query(
      'UPDATE surveys SET title = ?, description = ?, status = ? WHERE id = ?',
      [title, description || '', status || 'active', id]
    );

    // Replace questions: delete old, insert new
    if (questions) {
      await connection.query('DELETE FROM questions WHERE survey_id = ?', [id]);

      if (questions.length > 0) {
        const questionValues = questions.map((q, index) => [
          id,
          q.text || '',
          q.type || 'Text Input',
          index,
        ]);

        await connection.query(
          'INSERT INTO questions (survey_id, question_text, question_type, question_order) VALUES ?',
          [questionValues]
        );
      }
    }

    await connection.commit();

    // Fetch updated
    const [updatedSurvey] = await pool.query('SELECT * FROM surveys WHERE id = ?', [id]);
    const [updatedQuestions] = await pool.query(
      'SELECT * FROM questions WHERE survey_id = ? ORDER BY question_order ASC',
      [id]
    );

    res.json({
      success: true,
      message: 'Survey updated successfully.',
      data: {
        ...updatedSurvey[0],
        questions: updatedQuestions,
      },
    });
  } catch (error) {
    await connection.rollback();
    console.error('Update survey error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  } finally {
    connection.release();
  }
}

/**
 * DELETE /api/surveys/:id
 * Deletes a survey and all its questions/responses (CASCADE).
 */
async function deleteSurvey(req, res) {
  try {
    const { id } = req.params;

    const [result] = await pool.query('DELETE FROM surveys WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Survey not found.',
      });
    }

    res.json({
      success: true,
      message: 'Survey deleted successfully.',
    });
  } catch (error) {
    console.error('Delete survey error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error.',
    });
  }
}

module.exports = {
  getAllSurveys,
  getSurveyById,
  createSurvey,
  updateSurvey,
  deleteSurvey,
};
