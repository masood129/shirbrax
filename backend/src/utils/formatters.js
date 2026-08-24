import { db } from '../config/database.js';
import {
  canViewAuthorContent,
  canViewPost,
  getActiveSubscription,
  getFollowStatus,
  getViewerContext,
  normalizeVisibility,
} from './access.js';

export function getBaseUrl(req) {
  const host = req.get('host');
  const protocol = req.protocol;
  return `${protocol}://${host}`;
}

export function formatMediaUrl(url, req) {
  if (!url) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  const baseUrl = getBaseUrl(req);
  return `${baseUrl}${url.startsWith('/') ? '' : '/'}${url}`;
}

/**
 * Shapes a user row for the client.
 *
 * `viewer` is the authenticated user (`req.user`) or null for a guest — the
 * whole object, not just the id, because access decisions depend on `role`.
 */
export async function formatUser(rawUser, viewer = null, req = null) {
  if (!rawUser) return null;

  const userId = rawUser.id;
  const viewerId = viewer ? viewer.id : null;
  const isSelf = Boolean(viewerId && String(viewerId) === String(userId));

  const [followersRes, followingRes, postsRes, followStatus, activeSub, pendingRes] =
    await Promise.all([
      db.get(
        "SELECT COUNT(*) as count FROM follows WHERE following_id = ? AND status = 'accepted'",
        [userId]
      ),
      db.get(
        "SELECT COUNT(*) as count FROM follows WHERE follower_id = ? AND status = 'accepted'",
        [userId]
      ),
      db.get('SELECT COUNT(*) as count FROM posts WHERE user_id = ?', [userId]),
      getFollowStatus(viewerId, userId),
      getActiveSubscription(viewerId, userId),
      // Only the account owner needs to know how many requests are waiting.
      isSelf
        ? db.get(
            "SELECT COUNT(*) as count FROM follows WHERE following_id = ? AND status = 'pending'",
            [userId]
          )
        : Promise.resolve(null),
    ]);

  const ctx = await getViewerContext(viewer, rawUser);
  const avatar = req && rawUser.avatar ? formatMediaUrl(rawUser.avatar, req) : rawUser.avatar;

  return {
    id: rawUser.id.toString(),
    name: rawUser.name,
    username: rawUser.username,
    email: rawUser.email,
    avatar: avatar || null,
    bio: rawUser.bio || null,
    role: rawUser.role || 'user',
    followers_count: followersRes ? followersRes.count : 0,
    following_count: followingRes ? followingRes.count : 0,
    posts_count: postsRes ? postsRes.count : 0,
    is_following: followStatus === 'accepted',
    follow_status: followStatus, // 'accepted' | 'pending' | 'none'
    is_banned: Boolean(rawUser.is_banned),

    // ─── Privacy & subscription ─────────────────────────────
    is_private: Boolean(rawUser.is_private),
    subscription_enabled: Boolean(rawUser.subscription_enabled),
    subscription_price: rawUser.subscription_price || 0,
    is_subscribed: Boolean(activeSub),
    subscription_expires_at: activeSub ? activeSub.expires_at : null,
    /// False when the viewer may not browse this account's posts at all.
    can_view_posts: canViewAuthorContent(rawUser, ctx),
    pending_requests_count: pendingRes ? pendingRes.count : 0,

    created_at: rawUser.created_at,
  };
}

/**
 * Shapes a post row for the client, stripping the media of any post the viewer
 * is not allowed to open. A locked post still carries its author, caption and
 * counts so the client can render a teaser with the right call to action.
 *
 * Pass `ctx` when formatting many posts by the same author to avoid re-running
 * the relationship queries per post.
 */
export async function formatPost(rawPost, viewer = null, req = null, ctx = null) {
  if (!rawPost) return null;

  const viewerId = viewer ? viewer.id : null;
  const authorRaw = await db.get('SELECT * FROM users WHERE id = ?', [rawPost.user_id]);
  const author = await formatUser(authorRaw, viewer, req);

  const viewerCtx = ctx || (await getViewerContext(viewer, authorRaw));
  const { allowed, reason } = canViewPost(rawPost, authorRaw, viewerCtx);

  const [likesRes, commentsRes, likeCheck] = await Promise.all([
    db.get('SELECT COUNT(*) as count FROM likes WHERE post_id = ?', [rawPost.id]),
    db.get('SELECT COUNT(*) as count FROM comments WHERE post_id = ?', [rawPost.id]),
    viewerId
      ? db.get('SELECT id FROM likes WHERE user_id = ? AND post_id = ?', [viewerId, rawPost.id])
      : Promise.resolve(null),
  ]);

  let tags = [];
  if (rawPost.tags) {
    try {
      tags = JSON.parse(rawPost.tags);
      if (!Array.isArray(tags)) tags = [];
    } catch {
      tags = rawPost.tags.split(',').map((t) => t.trim()).filter(Boolean);
    }
  }

  // Media is resolved only when access is granted — a locked post must never
  // carry a usable URL, whether the file is local or an external link.
  const mediaUrl = allowed && req ? formatMediaUrl(rawPost.media_url, req) : null;
  const thumbnailUrl =
    allowed && req && rawPost.thumbnail_url
      ? formatMediaUrl(rawPost.thumbnail_url, req)
      : null;

  return {
    id: rawPost.id.toString(),
    author,
    caption: rawPost.caption || null,
    media_type: rawPost.media_type,
    media_url: allowed ? mediaUrl ?? rawPost.media_url : null,
    thumbnail_url: allowed ? thumbnailUrl ?? rawPost.thumbnail_url ?? null : null,
    likes_count: likesRes ? likesRes.count : 0,
    comments_count: commentsRes ? commentsRes.count : 0,
    is_liked: Boolean(likeCheck),
    tags,
    video_duration: rawPost.video_duration || null,
    visibility: normalizeVisibility(rawPost.visibility),
    is_locked: !allowed,
    lock_reason: reason,
    created_at: rawPost.created_at,
  };
}

export async function formatComment(rawComment, viewer = null, req = null) {
  if (!rawComment) return null;

  const viewerId = viewer ? viewer.id : null;
  const authorRaw = await db.get('SELECT * FROM users WHERE id = ?', [rawComment.user_id]);
  const author = await formatUser(authorRaw, viewer, req);

  const [likesRes, likeCheck] = await Promise.all([
    db.get('SELECT COUNT(*) as count FROM comment_likes WHERE comment_id = ?', [rawComment.id]),
    viewerId
      ? db.get('SELECT id FROM comment_likes WHERE user_id = ? AND comment_id = ?', [
          viewerId,
          rawComment.id,
        ])
      : Promise.resolve(null),
  ]);

  return {
    id: rawComment.id.toString(),
    post_id: rawComment.post_id.toString(),
    author,
    text: rawComment.text,
    likes_count: likesRes ? likesRes.count : 0,
    is_liked: Boolean(likeCheck),
    created_at: rawComment.created_at,
  };
}
