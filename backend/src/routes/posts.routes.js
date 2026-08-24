import express from 'express';
import { db } from '../config/database.js';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { formatPost, formatComment } from '../utils/formatters.js';
import {
  buildPostVisibilityFilter,
  canViewPostById,
  LOCK_REASON,
  VISIBILITY,
  VISIBILITY_VALUES,
} from '../utils/access.js';

const router = express.Router();

// ─── Get Feed / List Posts ────────────────────────────────
router.get('/', optionalAuth, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const perPage = Math.min(50, Math.max(1, parseInt(req.query.per_page, 10) || 10));
    const offset = (page - 1) * perPage;
    const filterUserId = req.query.user_id;
    const filterMediaType = req.query.media_type;
    const filterTag = req.query.tag;

    let whereClauses = [];
    let params = [];

    if (filterUserId) {
      whereClauses.push('posts.user_id = ?');
      params.push(filterUserId);
    }

    if (filterMediaType && (filterMediaType === 'photo' || filterMediaType === 'video')) {
      whereClauses.push('posts.media_type = ?');
      params.push(filterMediaType);
    }

    if (filterTag) {
      whereClauses.push('posts.tags LIKE ?');
      params.push(`%${filterTag}%`);
    }

    // Access control — must be applied last so its params stay in clause order.
    const visibility = buildPostVisibilityFilter(req.user || null);
    whereClauses.push(visibility.sql);
    params.push(...visibility.params);

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    const countRes = await db.get(`SELECT COUNT(*) as count FROM posts ${whereSql}`, params);
    const total = countRes ? countRes.count : 0;

    const rawPosts = await db.all(
      `SELECT posts.* FROM posts ${whereSql} ORDER BY posts.created_at DESC LIMIT ? OFFSET ?`,
      [...params, perPage, offset]
    );

    const formattedPosts = await Promise.all(
      rawPosts.map((p) => formatPost(p, req.user || null, req))
    );

    return res.json({
      data: formattedPosts,
      total,
      page,
      per_page: perPage,
      has_more: offset + rawPosts.length < total,
    });
  } catch (error) {
    console.error('Get posts error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت پست‌ها.' });
  }
});

// ─── Explore Posts ────────────────────────────────────────
router.get('/explore', optionalAuth, async (req, res) => {
  try {
    const query = req.query.query ? req.query.query.trim() : '';
    const visibility = buildPostVisibilityFilter(req.user || null);

    let rawPosts;
    if (query) {
      rawPosts = await db.all(
        `SELECT * FROM posts
         WHERE (caption LIKE ? OR tags LIKE ?) AND ${visibility.sql}
         ORDER BY created_at DESC LIMIT 30`,
        [`%${query}%`, `%${query}%`, ...visibility.params]
      );
    } else {
      rawPosts = await db.all(
        `SELECT posts.*, COUNT(likes.id) as like_count
         FROM posts
         LEFT JOIN likes ON posts.id = likes.post_id
         WHERE ${visibility.sql}
         GROUP BY posts.id
         ORDER BY like_count DESC, posts.created_at DESC
         LIMIT 30`,
        visibility.params
      );
    }

    const formattedPosts = await Promise.all(
      rawPosts.map((p) => formatPost(p, req.user || null, req))
    );

    return res.json({ data: formattedPosts });
  } catch (error) {
    console.error('Explore posts error:', error);
    return res.status(500).json({ message: 'خطای سرور در کاوش پست‌ها.' });
  }
});

// ─── Upload Media & Create Post ───────────────────────────
router.post('/upload', requireAuth, upload.single('file'), async (req, res) => {
  try {
    const { caption, media_type, tags } = req.body;

    if (!req.file && !req.body.media_url) {
      return res.status(400).json({ message: 'فایل تصویر یا ویدیو الزامی است.' });
    }

    // Visibility — reject an unknown value instead of silently downgrading it
    // to public, which would leak content the author meant to restrict.
    const requestedVisibility = req.body.visibility || VISIBILITY.PUBLIC;
    if (!VISIBILITY_VALUES.includes(requestedVisibility)) {
      return res.status(400).json({
        message: `سطح دسترسی نامعتبر است. مقادیر مجاز: ${VISIBILITY_VALUES.join('، ')}`,
      });
    }

    if (
      requestedVisibility === VISIBILITY.SUBSCRIBERS &&
      !req.user.subscription_enabled
    ) {
      return res.status(400).json({
        message: 'برای انتشار پست اشتراکی، ابتدا اشتراک را در تنظیمات فعال کنید.',
      });
    }

    let mediaUrl;
    let thumbnailUrl = null;

    if (req.file) {
      mediaUrl = `/uploads/${req.file.filename}`;
      // For images, thumbnail can be the same url
      if (media_type !== 'video') {
        thumbnailUrl = mediaUrl;
      }
    } else {
      mediaUrl = req.body.media_url;
      thumbnailUrl = req.body.thumbnail_url || mediaUrl;
    }

    const detectedType =
      media_type ||
      (req.file?.mimetype?.startsWith('video/') ? 'video' : 'photo');

    let processedTags = [];
    if (tags) {
      if (Array.isArray(tags)) {
        processedTags = tags;
      } else if (typeof tags === 'string') {
        try {
          const parsed = JSON.parse(tags);
          processedTags = Array.isArray(parsed) ? parsed : tags.split(',').map((t) => t.trim());
        } catch {
          processedTags = tags.split(',').map((t) => t.trim()).filter(Boolean);
        }
      }
    }

    const createdAt = new Date().toISOString();

    const result = await db.run(
      `INSERT INTO posts (user_id, caption, media_type, media_url, thumbnail_url, tags, video_duration, visibility, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        caption ? caption.trim() : null,
        detectedType,
        mediaUrl,
        thumbnailUrl,
        JSON.stringify(processedTags),
        req.body.video_duration ? parseInt(req.body.video_duration, 10) : null,
        requestedVisibility,
        createdAt,
      ]
    );

    const newPost = await db.get('SELECT * FROM posts WHERE id = ?', [result.lastID]);
    const formattedPost = await formatPost(newPost, req.user, req);

    return res.status(201).json(formattedPost);
  } catch (error) {
    console.error('Upload post error:', error);
    return res.status(500).json({ message: 'خطای سرور در ایجاد پست.' });
  }
});

// ─── Get Single Post ──────────────────────────────────────
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const access = await canViewPostById(req.params.id, req.user || null);

    if (!access.post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }

    // A subscriber-only post is still returned as a locked teaser so the
    // client can render the paywall. Follower-gated and private-account
    // content is refused outright.
    if (!access.allowed && access.reason !== LOCK_REASON.SUBSCRIBERS_ONLY) {
      return res.status(403).json({
        message:
          access.reason === LOCK_REASON.PRIVATE_ACCOUNT
            ? 'این حساب خصوصی است. برای دیدن پست‌ها باید دنبال‌کننده تأییدشده باشید.'
            : 'این پست فقط برای دنبال‌کنندگان قابل مشاهده است.',
        lock_reason: access.reason,
      });
    }

    const formatted = await formatPost(access.post, req.user || null, req, access.ctx);
    return res.json(formatted);
  } catch (error) {
    console.error('Get post error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت پست.' });
  }
});

// ─── Like / Unlike Post ───────────────────────────────────
router.post('/:id/like', requireAuth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    const access = await canViewPostById(postId, req.user);
    if (!access.post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }
    if (!access.allowed) {
      return res.status(403).json({
        message: 'برای لایک کردن این پست باید به آن دسترسی داشته باشید.',
        lock_reason: access.reason,
      });
    }
    const post = access.post;

    const existingLike = await db.get(
      'SELECT id FROM likes WHERE user_id = ? AND post_id = ?',
      [userId, postId]
    );

    let isLiked = false;
    if (existingLike) {
      await db.run('DELETE FROM likes WHERE id = ?', [existingLike.id]);
      isLiked = false;
    } else {
      await db.run('INSERT INTO likes (user_id, post_id, created_at) VALUES (?, ?, ?)', [
        userId,
        postId,
        new Date().toISOString(),
      ]);
      isLiked = true;

      // Create notification for post author if not own post
      if (post.user_id !== userId) {
        await db.run(
          `INSERT INTO notifications (user_id, actor_id, type, post_id, message, is_read, created_at)
           VALUES (?, ?, 'like', ?, 'پست شما را لایک کرد', 0, ?)`,
          [post.user_id, userId, postId, new Date().toISOString()]
        );
      }
    }

    const likesCountRes = await db.get('SELECT COUNT(*) as count FROM likes WHERE post_id = ?', [
      postId,
    ]);

    return res.json({
      is_liked: isLiked,
      likes_count: likesCountRes ? likesCountRes.count : 0,
      message: isLiked ? 'پست لایک شد.' : 'لایک پست برداشته شد.',
    });
  } catch (error) {
    console.error('Like post error:', error);
    return res.status(500).json({ message: 'خطای سرور در لایک پست.' });
  }
});

// ─── Delete Post ──────────────────────────────────────────
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const post = await db.get('SELECT * FROM posts WHERE id = ?', [req.params.id]);
    if (!post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }

    // Only owner or admin
    if (post.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'شما اجازه حذف این پست را ندارید.' });
    }

    await db.run('DELETE FROM posts WHERE id = ?', [req.params.id]);
    return res.json({ message: 'پست با موفقیت حذف شد.' });
  } catch (error) {
    console.error('Delete post error:', error);
    return res.status(500).json({ message: 'خطای سرور در حذف پست.' });
  }
});

// ─── Get Post Comments ────────────────────────────────────
router.get('/:id/comments', optionalAuth, async (req, res) => {
  try {
    const postId = req.params.id;

    const access = await canViewPostById(postId, req.user || null);
    if (!access.post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }
    if (!access.allowed) {
      return res.status(403).json({
        message: 'نظرات این پست برای شما قابل مشاهده نیست.',
        lock_reason: access.reason,
      });
    }

    const rawComments = await db.all(
      'SELECT * FROM comments WHERE post_id = ? ORDER BY created_at DESC',
      [postId]
    );

    const formattedComments = await Promise.all(
      rawComments.map((c) => formatComment(c, req.user || null, req))
    );

    return res.json({ data: formattedComments });
  } catch (error) {
    console.error('Get comments error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت نظرات.' });
  }
});

// ─── Add Comment ──────────────────────────────────────────
router.post('/:id/comments', requireAuth, async (req, res) => {
  try {
    const postId = req.params.id;
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ message: 'متن نظر نمی‌تواند خالی باشد.' });
    }

    const post = await db.get('SELECT * FROM posts WHERE id = ?', [postId]);
    if (!post) {
      return res.status(404).json({ message: 'پست یافت نشد.' });
    }

    const access = await canViewPostById(postId, req.user);
    if (!access.allowed) {
      return res.status(403).json({
        message: 'برای ارسال نظر باید به این پست دسترسی داشته باشید.',
        lock_reason: access.reason,
      });
    }

    const createdAt = new Date().toISOString();
    const result = await db.run(
      'INSERT INTO comments (post_id, user_id, text, created_at) VALUES (?, ?, ?, ?)',
      [postId, req.user.id, text.trim(), createdAt]
    );

    // Create notification if not own post
    if (post.user_id !== req.user.id) {
      await db.run(
        `INSERT INTO notifications (user_id, actor_id, type, post_id, message, is_read, created_at)
         VALUES (?, ?, 'comment', ?, ?, 0, ?)`,
        [post.user_id, req.user.id, postId, `نظر گذاشت: ${text.trim().substring(0, 30)}...`, createdAt]
      );
    }

    const newComment = await db.get('SELECT * FROM comments WHERE id = ?', [result.lastID]);
    const formatted = await formatComment(newComment, req.user, req);

    return res.status(201).json(formatted);
  } catch (error) {
    console.error('Add comment error:', error);
    return res.status(500).json({ message: 'خطای سرور در ثبت نظر.' });
  }
});

// ─── Like / Unlike Comment ────────────────────────────────
router.post('/:id/comments/:commentId/like', requireAuth, async (req, res) => {
  try {
    const commentId = req.params.commentId;
    const userId = req.user.id;

    const comment = await db.get('SELECT * FROM comments WHERE id = ?', [commentId]);
    if (!comment) {
      return res.status(404).json({ message: 'نظر یافت نشد.' });
    }

    // The comment inherits its post's access rules.
    const access = await canViewPostById(comment.post_id, req.user);
    if (!access.allowed) {
      return res.status(403).json({
        message: 'برای لایک این نظر باید به پست آن دسترسی داشته باشید.',
        lock_reason: access.reason,
      });
    }

    const existingLike = await db.get(
      'SELECT id FROM comment_likes WHERE user_id = ? AND comment_id = ?',
      [userId, commentId]
    );

    let isLiked = false;
    if (existingLike) {
      await db.run('DELETE FROM comment_likes WHERE id = ?', [existingLike.id]);
      isLiked = false;
    } else {
      await db.run(
        'INSERT INTO comment_likes (user_id, comment_id, created_at) VALUES (?, ?, ?)',
        [userId, commentId, new Date().toISOString()]
      );
      isLiked = true;
    }

    const countRes = await db.get(
      'SELECT COUNT(*) as count FROM comment_likes WHERE comment_id = ?',
      [commentId]
    );

    return res.json({
      is_liked: isLiked,
      likes_count: countRes ? countRes.count : 0,
    });
  } catch (error) {
    console.error('Like comment error:', error);
    return res.status(500).json({ message: 'خطای سرور در لایک نظر.' });
  }
});

export default router;
