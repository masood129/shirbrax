import path from 'path';
import { db } from '../config/database.js';
import { optionalAuth } from './auth.js';
import { canViewPost, getViewerContext } from '../utils/access.js';

/**
 * Guards the /uploads static mount.
 *
 * The API already refuses to hand out a URL for content the viewer cannot see,
 * but that alone is not enough: an upload filename is guessable and a URL can
 * be shared after the fact. This middleware re-checks access on the file itself,
 * so revoking a follow or letting a subscription lapse cuts off the media
 * immediately rather than at the next page load.
 *
 * Avatars stay public — they appear in search results and follower lists, where
 * the viewer has no relationship with the account yet.
 */
export async function guardUploads(req, res, next) {
  try {
    // req.path here is relative to the mount, e.g. '/media-123.jpg'
    const filename = path.basename(decodeURIComponent(req.path));
    if (!filename) return next();

    const relativeUrl = `/uploads/${filename}`;

    const post = await db.get(
      'SELECT * FROM posts WHERE media_url = ? OR thumbnail_url = ?',
      [relativeUrl, relativeUrl]
    );

    // Not post media (avatar, story, or an orphaned file) — serve as before.
    if (!post) return next();

    const author = await db.get('SELECT * FROM users WHERE id = ?', [post.user_id]);
    const ctx = await getViewerContext(req.user || null, author);
    const { allowed, reason } = canViewPost(post, author, ctx);

    if (!allowed) {
      return res.status(403).json({
        message: 'شما به این فایل دسترسی ندارید.',
        lock_reason: reason,
      });
    }

    return next();
  } catch (error) {
    console.error('[guardUploads]', error);
    return res.status(500).json({ message: 'خطای سرور در بررسی دسترسی فایل.' });
  }
}

/** optionalAuth must run first so guardUploads can see req.user. */
export const uploadsAccessChain = [optionalAuth, guardUploads];
