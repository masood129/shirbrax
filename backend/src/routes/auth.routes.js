import express from 'express';
import bcrypt from 'bcryptjs';
import { db } from '../config/database.js';
import { signToken, requireAuth } from '../middleware/auth.js';
import { formatUser } from '../utils/formatters.js';

const router = express.Router();

// ─── Register ─────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const { name, username, email, password } = req.body;

    if (!name || !username || !email || !password) {
      return res.status(400).json({ message: 'لطفاً تمام فیلدهای الزامی را وارد کنید.' });
    }

    const trimmedUsername = username.trim().toLowerCase();
    const trimmedEmail = email.trim().toLowerCase();

    // Check existing
    const existing = await db.get(
      'SELECT id, username, email FROM users WHERE username = ? OR email = ?',
      [trimmedUsername, trimmedEmail]
    );

    if (existing) {
      if (existing.email === trimmedEmail) {
        return res.status(400).json({ message: 'این ایمیل قبلاً ثبت شده است.' });
      }
      return res.status(400).json({ message: 'این نام کاربری قبلاً انتخاب شده است.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const createdAt = new Date().toISOString();

    const result = await db.run(
      `INSERT INTO users (name, username, email, password, role, is_banned, created_at)
       VALUES (?, ?, ?, ?, 'user', 0, ?)`,
      [name.trim(), trimmedUsername, trimmedEmail, hashedPassword, createdAt]
    );

    const newUser = await db.get('SELECT * FROM users WHERE id = ?', [result.lastID]);
    const token = signToken(newUser);
    const formattedUser = await formatUser(newUser, newUser, req);

    return res.status(201).json({
      token,
      user: formattedUser,
      message: 'ثبت‌نام با موفقیت انجام شد.',
    });
  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json({ message: 'خطای سرور در ثبت‌نام.' });
  }
});

// ─── Login ────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'ایمیل و رمز عبور الزامی است.' });
    }

    const trimmedIdentifier = email.trim().toLowerCase();

    const user = await db.get(
      'SELECT * FROM users WHERE email = ? OR username = ?',
      [trimmedIdentifier, trimmedIdentifier]
    );

    if (!user) {
      return res.status(400).json({ message: 'ایمیل یا رمز عبور اشتباه است.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'ایمیل یا رمز عبور اشتباه است.' });
    }

    if (user.is_banned) {
      return res.status(403).json({ message: 'حساب کاربری شما مسدود شده است.' });
    }

    const token = signToken(user);
    const formattedUser = await formatUser(user, user, req);

    return res.json({
      token,
      user: formattedUser,
      message: 'ورود با موفقیت انجام شد.',
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ message: 'خطای سرور در ورود.' });
  }
});

// ─── Me ───────────────────────────────────────────────────
router.get('/me', requireAuth, async (req, res) => {
  try {
    const formatted = await formatUser(req.user, req.user, req);
    return res.json(formatted);
  } catch (error) {
    console.error('Get me error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت اطلاعات کاربر.' });
  }
});

// ─── Refresh Token ────────────────────────────────────────
router.post('/refresh', requireAuth, async (req, res) => {
  try {
    const token = signToken(req.user);
    const formatted = await formatUser(req.user, req.user, req);
    return res.json({ token, user: formatted });
  } catch (error) {
    return res.status(500).json({ message: 'خطای سرور در تمدید توکن.' });
  }
});

// ─── Logout ───────────────────────────────────────────────
router.post('/logout', (req, res) => {
  return res.json({ message: 'با موفقیت خارج شدید.' });
});

export default router;
