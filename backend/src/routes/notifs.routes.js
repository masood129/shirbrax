import express from 'express';
import { db } from '../config/database.js';
import { requireAuth } from '../middleware/auth.js';
import { formatMediaUrl } from '../utils/formatters.js';

const router = express.Router();

router.use(requireAuth);

// ─── List Notifications ───────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const rawNotifs = await db.all(
      `SELECT n.*, u.name as actor_name, u.avatar as actor_avatar, p.thumbnail_url as post_thumbnail, p.media_url as post_media_url
       FROM notifications n
       JOIN users u ON n.actor_id = u.id
       LEFT JOIN posts p ON n.post_id = p.id
       WHERE n.user_id = ?
       ORDER BY n.created_at DESC
       LIMIT 50`,
      [req.user.id]
    );

    const formatted = rawNotifs.map((n) => ({
      id: n.id.toString(),
      type: n.type,
      actorName: n.actor_name,
      actorAvatar: n.actor_avatar ? formatMediaUrl(n.actor_avatar, req) : null,
      postThumbnail: n.post_thumbnail
        ? formatMediaUrl(n.post_thumbnail, req)
        : n.post_media_url
        ? formatMediaUrl(n.post_media_url, req)
        : null,
      postId: n.post_id ? n.post_id.toString() : null,
      message: n.message,
      isRead: Boolean(n.is_read),
      createdAt: n.created_at,
    }));

    return res.json({ data: formatted });
  } catch (error) {
    console.error('Get notifications error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت اعلان‌ها.' });
  }
});

// ─── Mark as Read ─────────────────────────────────────────
router.patch('/:id/read', async (req, res) => {
  try {
    await db.run('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?', [
      req.params.id,
      req.user.id,
    ]);
    return res.json({ message: 'اعلان خوانده شد.' });
  } catch (error) {
    return res.status(500).json({ message: 'خطای سرور در بروزرسانی وضعیت اعلان.' });
  }
});

// ─── Mark All as Read ─────────────────────────────────────
router.post('/read-all', async (req, res) => {
  try {
    await db.run('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [req.user.id]);
    return res.json({ message: 'تمام اعلان‌ها خوانده شدند.' });
  } catch (error) {
    return res.status(500).json({ message: 'خطای سرور در بروزرسانی اعلان‌ها.' });
  }
});

export default router;
