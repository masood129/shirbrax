import jwt from 'jsonwebtoken';
import { db } from '../config/database.js';

const JWT_SECRET = process.env.JWT_SECRET || 'shirbrax_super_secret_jwt_key_2026_change_in_production';

export function signToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
      username: user.username,
    },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
  );
}

export async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'توکن احراز هویت ارسال نشده است.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    const user = await db.get('SELECT * FROM users WHERE id = ?', [decoded.id]);
    if (!user) {
      return res.status(401).json({ message: 'کاربر مورد نظر یافت نشد.' });
    }

    if (user.is_banned) {
      return res.status(403).json({ message: 'حساب کاربری شما مسدود شده است.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'توکن نامعتبر یا منقضی شده است.' });
  }
}

export async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      const user = await db.get('SELECT * FROM users WHERE id = ?', [decoded.id]);
      if (user && !user.is_banned) {
        req.user = user;
      }
    }
  } catch {
    // ignore token error in optional auth
  }
  next();
}

export function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ message: 'دسترسی فقط برای مدیران سیستم مجاز است.' });
  }
  next();
}
