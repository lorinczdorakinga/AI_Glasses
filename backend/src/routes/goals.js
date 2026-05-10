const router = require('express').Router();
const pool   = require('../config/db');
const auth   = require('../middleware/auth');

// Save or update user goal
router.post('/', auth, async (req, res) => {
  const { goal, summary_time } = req.body;
  const userId = req.user.id;

  if (!goal || !summary_time)
    return res.status(400).json({ error: 'Goal and summary time are required' });

  try {
    // If user already has a goal, update it; otherwise insert
    const existing = await pool.query(
      'SELECT id FROM user_goals WHERE user_id = $1', [userId]
    );

    let result;
    if (existing.rows.length > 0) {
      result = await pool.query(
        'UPDATE user_goals SET goal = $1, summary_time = $2, updated_at = NOW() WHERE user_id = $3 RETURNING *',
        [goal, summary_time, userId]
      );
    } else {
      result = await pool.query(
        'INSERT INTO user_goals (user_id, goal, summary_time) VALUES ($1, $2, $3) RETURNING *',
        [userId, goal, summary_time]
      );
    }

    // This is the JSON that gets saved and can be sent through the server
    const responseJson = {
      user_id:      userId,
      goal:         result.rows[0].goal,
      summary_time: result.rows[0].summary_time,
      saved_at:     result.rows[0].updated_at,
    };

    res.status(200).json(responseJson);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get current user goal
router.get('/', auth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM user_goals WHERE user_id = $1', [req.user.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'No goal set yet' });

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;