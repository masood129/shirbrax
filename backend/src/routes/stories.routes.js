import express from 'express';
import { db } from '../config/database.js';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { formatMediaUrl } from '../utils/formatters.js';

const router = express.Router();

// ─── List Active Stories ──────────────────────────────────
router.get('/', optionalAuth, async (req, res) => {
  try {
    const nowIso = new Date().toISOString();
    const viewerId = req.user ? req.user.id : null;
    const isAdmin = req.user && req.user.role === 'admin' ? 1 : 0;

    // A private account's stories are visible only to accepted followers.
    const rawStories = await db.all(
      `SELECT s.*, u.name, u.username, u.avatar
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE s.expires_at > ? AND u.is_banned = 0
         AND (
           u.id = ?
           OR ? = 1
           OR COALESCE(u.is_private, 0) = 0
           OR EXISTS (
             SELECT 1 FROM follows f
             WHERE f.follower_id = ? AND f.following_id = u.id AND f.status = 'accepted'
           )
         )
       ORDER BY s.created_at ASC`,
      [nowIso, viewerId, isAdmin, viewerId]
    );

    // Group by user
    const usersMap = new Map();
    for (const story of rawStories) {
      if (!usersMap.has(story.user_id)) {
        usersMap.set(story.user_id, {
          user: {
            id: story.user_id.toString(),
            name: story.name,
            username: story.username,
            avatar: story.avatar ? formatMediaUrl(story.avatar, req) : null,
          },
          items: [],
        });
      }
      usersMap.get(story.user_id).items.push({
        id: story.id.toString(),
        media_url: formatMediaUrl(story.media_url, req),
        media_type: story.media_type,
        caption: story.caption,
        created_at: story.created_at,
        expires_at: story.expires_at,
      });
    }

    return res.json({ data: Array.from(usersMap.values()) });
  } catch (error) {
    console.error('Get stories error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت استوری‌ها.' });
  }
});

// ─── Create Story ─────────────────────────────────────────
router.post('/', requireAuth, upload.single('file'), async (req, res) => {
  try {
    if (!req.file && !req.body.media_url) {
      return res.status(400).json({ message: 'فایل استوری الزامی است.' });
    }

    const mediaUrl = req.file ? `/uploads/${req.file.filename}` : req.body.media_url;
    const mediaType = req.body.media_type || (req.file?.mimetype?.startsWith('video/') ? 'video' : 'photo');
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 24 * 60 * 60 * 1000);

    const result = await db.run(
      `INSERT INTO stories (user_id, media_url, media_type, caption, created_at, expires_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        mediaUrl,
        mediaType,
        req.body.caption || null,
        createdAt.toISOString(),
        expiresAt.toISOString(),
      ]
    );

    return res.status(201).json({
      id: result.lastID.toString(),
      media_url: formatMediaUrl(mediaUrl, req),
      media_type: mediaType,
      caption: req.body.caption || null,
      created_at: createdAt.toISOString(),
      expires_at: expiresAt.toISOString(),
    });
  } catch (error) {
    console.error('Create story error:', error);
    return res.status(500).json({ message: 'خطای سرور در ایجاد استوری.' });
  }
});

export default router;
