const router  = require('express').Router();
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const pool    = require('../config/db');
const { Resend } = require('resend');
const resend  = new Resend(process.env.RESEND_API_KEY);

// ── REGISTER ──────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password)
    return res.status(400).json({ error: 'All fields are required' });

  if (password.length < 6)
    return res.status(400).json({ error: 'Password must be at least 6 characters' });

  try {
    const exists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (exists.rows.length > 0)
      return res.status(409).json({ error: 'Email already registered' });

    const hash = await bcrypt.hash(password, 12);
    const result = await pool.query(
      'INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email, created_at',
      [name, email, hash]
    );

    const user  = result.rows[0];
    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN,
    });

    res.status(201).json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── LOGIN ──────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ error: 'Email and password are required' });

  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0)
      return res.status(401).json({ error: 'Invalid credentials' });

    const user  = result.rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN,
    });

    const { password: _, ...safeUser } = user;
    res.json({ user: safeUser, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── SEND RESET CODE ───────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email)
    return res.status(400).json({ error: 'Email is required' });

  try {
    const exists = await pool.query(
      'SELECT id FROM users WHERE email = $1', [email]
    );

    if (exists.rows.length === 0)
      return res.json({ message: 'If that email exists, a code has been sent' });

    const code      = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await pool.query(
      'DELETE FROM password_reset_codes WHERE email = $1', [email]
    );

    await pool.query(
      'INSERT INTO password_reset_codes (email, code, expires_at) VALUES ($1, $2, $3)',
      [email, code, expiresAt]
    );

    await resend.emails.send({
      from:    process.env.FROM_EMAIL,
      to:      email,
      subject: 'Your password reset code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto;">
          <h2 style="color: #4f46e5;">Reset your password</h2>
          <p>Use the code below to reset your password. It expires in <strong>15 minutes</strong>.</p>
          <div style="background: #f3f4f6; padding: 24px; border-radius: 8px; text-align: center;">
            <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #4f46e5;">
              ${code}
            </span>
          </div>
          <p style="color: #6b7280; margin-top: 16px;">
            If you didn't request this, you can safely ignore this email.
          </p>
        </div>
      `,
    });

    res.json({ message: 'If that email exists, a code has been sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── VERIFY CODE & RESET PASSWORD ──────────────────────────
router.post('/reset-password', async (req, res) => {
  const { email, code, new_password } = req.body;

  if (!email || !code || !new_password)
    return res.status(400).json({ error: 'All fields are required' });

  if (new_password.length < 6)
    return res.status(400).json({ error: 'Password must be at least 6 characters' });

  try {
    const result = await pool.query(
      'SELECT * FROM password_reset_codes WHERE email = $1 AND code = $2 AND used = FALSE',
      [email, code]
    );

    if (result.rows.length === 0)
      return res.status(400).json({ error: 'Invalid or expired code' });

    const resetEntry = result.rows[0];

    if (new Date() > new Date(resetEntry.expires_at))
      return res.status(400).json({ error: 'Code has expired, please request a new one' });

    const hash = await bcrypt.hash(new_password, 12);
    await pool.query(
      'UPDATE users SET password = $1, updated_at = NOW() WHERE email = $2',
      [hash, email]
    );

    await pool.query(
      'UPDATE password_reset_codes SET used = TRUE WHERE id = $1',
      [resetEntry.id]
    );

    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;