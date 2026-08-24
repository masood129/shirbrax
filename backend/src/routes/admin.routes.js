import express from 'express';
import { db } from '../config/database.js';
import { requireAuth, requireAdmin } from '../middleware/auth.js';
import { formatUser, formatPost } from '../utils/formatters.js';

const router = express.Router();

// Apply auth + admin to all admin routes
router.use(requireAuth, requireAdmin);

// ─── Admin Dashboard Stats ────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const [usersCount, postsCount, videosCount, likesCount] = await Promise.all([
      db.get('SELECT COUNT(*) as count FROM users'),
      db.get('SELECT COUNT(*) as count FROM posts'),
      db.get("SELECT COUNT(*) as count FROM posts WHERE media_type = 'video'"),
      db.get('SELECT COUNT(*) as count FROM likes'),
    ]);

    return res.json({
      users_count: usersCount ? usersCount.count : 0,
      posts_count: postsCount ? postsCount.count : 0,
      videos_count: videosCount ? videosCount.count : 0,
      likes_count: likesCount ? likesCount.count : 0,
    });
  } catch (error) {
    console.error('Admin stats error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت آمار ادمین.' });
  }
});

// ─── Admin Users List ─────────────────────────────────────
router.get('/users', async (req, res) => {
  try {
    const search = req.query.search ? req.query.search.trim() : '';

    let rawUsers;
    if (search) {
      rawUsers = await db.all(
        'SELECT * FROM users WHERE name LIKE ? OR username LIKE ? OR email LIKE ? ORDER BY created_at DESC',
        [`%${search}%`, `%${search}%`, `%${search}%`]
      );
    } else {
      rawUsers = await db.all('SELECT * FROM users ORDER BY created_at DESC');
    }

    const formatted = await Promise.all(
      rawUsers.map((u) => formatUser(u, req.user, req))
    );

    return res.json({ data: formatted });
  } catch (error) {
    console.error('Admin users list error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت لیست کاربران.' });
  }
});

// ─── Admin Posts List ─────────────────────────────────────
router.get('/posts', async (req, res) => {
  try {
    const mediaType = req.query.media_type;

    let rawPosts;
    if (mediaType && (mediaType === 'photo' || mediaType === 'video')) {
      rawPosts = await db.all(
        'SELECT * FROM posts WHERE media_type = ? ORDER BY created_at DESC',
        [mediaType]
      );
    } else {
      rawPosts = await db.all('SELECT * FROM posts ORDER BY created_at DESC');
    }

    const formatted = await Promise.all(
      rawPosts.map((p) => formatPost(p, req.user, req))
    );

    return res.json({ data: formatted });
  } catch (error) {
    console.error('Admin posts list error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت پست‌ها.' });
  }
});

// ─── Ban / Unban User ─────────────────────────────────────
router.post('/users/:id/ban', async (req, res) => {
  try {
    const targetUserId = req.params.id;

    const user = await db.get('SELECT * FROM users WHERE id = ?', [targetUserId]);
    if (!user) {
      return res.status(404).json({ message: 'کاربر مورد نظر یافت نشد.' });
    }

    if (user.role === 'admin') {
      return res.status(400).json({ message: 'نمی‌توان کاربر مدیر را مسدود کرد.' });
    }

    const newBanStatus = user.is_banned ? 0 : 1;
    await db.run('UPDATE users SET is_banned = ? WHERE id = ?', [newBanStatus, targetUserId]);

    return res.json({
      is_banned: Boolean(newBanStatus),
      message: newBanStatus ? 'کاربر با موفقیت مسدود شد.' : 'مسدودیت کاربر لغو شد.',
    });
  } catch (error) {
    console.error('Ban user error:', error);
    return res.status(500).json({ message: 'خطای سرور در تغییر وضعیت مسدودیت کاربر.' });
  }
});

// ─── Admin Delete Post ────────────────────────────────────
router.delete('/posts/:id', async (req, res) => {
  try {
    const postId = req.params.id;
    const post = await db.get('SELECT * FROM posts WHERE id = ?', [postId]);

    if (!post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }

    await db.run('DELETE FROM posts WHERE id = ?', [postId]);
    return res.json({ message: 'پست با موفقیت توسط مدیر حذف شد.' });
  } catch (error) {
    console.error('Admin delete post error:', error);
    return res.status(500).json({ message: 'خطای سرور در حذف پست.' });
  }
});

export default router;
