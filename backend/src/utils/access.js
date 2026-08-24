import { db } from '../config/database.js';

/**
 * Content access control — the single source of truth for "can this viewer
 * see this content?". Every read path must go through this module; do not
 * re-implement follow/subscription checks inside route handlers.
 *
 * Two independent gates stack on top of each other:
 *   1. Account gate — a private account's content requires an accepted follow.
 *   2. Post gate    — each post carries its own visibility level.
 */

export const VISIBILITY = {
  PUBLIC: 'public',
  FOLLOWERS: 'followers',
  SUBSCRIBERS: 'subscribers',
};

export const VISIBILITY_VALUES = Object.values(VISIBILITY);

/** Why a post was locked, sent to the client so it can render the right CTA. */
export const LOCK_REASON = {
  PRIVATE_ACCOUNT: 'private_account',
  FOLLOWERS_ONLY: 'followers_only',
  SUBSCRIBERS_ONLY: 'subscribers_only',
};

export function normalizeVisibility(value) {
  return VISIBILITY_VALUES.includes(value) ? value : VISIBILITY.PUBLIC;
}

// ─── Relationship checks ────────────────────────────────────

/** True only for an *accepted* follow — pending requests grant nothing. */
export async function isAcceptedFollower(viewerId, authorId) {
  if (!viewerId || String(viewerId) === String(authorId)) return false;
  const row = await db.get(
    `SELECT id FROM follows
     WHERE follower_id = ? AND following_id = ? AND status = 'accepted'`,
    [viewerId, authorId]
  );
  return Boolean(row);
}

/** 'accepted' | 'pending' | 'none' — drives the follow button state. */
export async function getFollowStatus(viewerId, authorId) {
  if (!viewerId || String(viewerId) === String(authorId)) return 'none';
  const row = await db.get(
    'SELECT status FROM follows WHERE follower_id = ? AND following_id = ?',
    [viewerId, authorId]
  );
  return row ? row.status || 'accepted' : 'none';
}

/** An active subscription is one that is not cancelled and not yet expired. */
export async function getActiveSubscription(viewerId, creatorId) {
  if (!viewerId || String(viewerId) === String(creatorId)) return null;
  const row = await db.get(
    `SELECT * FROM subscriptions
     WHERE subscriber_id = ? AND creator_id = ?
       AND cancelled_at IS NULL AND expires_at > ?`,
    [viewerId, creatorId, new Date().toISOString()]
  );
  return row || null;
}

export async function hasActiveSubscription(viewerId, creatorId) {
  return Boolean(await getActiveSubscription(viewerId, creatorId));
}

// ─── Viewer context ─────────────────────────────────────────

/**
 * Resolves every relationship between a viewer and an author in one pass, so
 * a single request does not re-query the same facts per post.
 * `viewer` is `req.user` (or null for a guest).
 */
export async function getViewerContext(viewer, author) {
  const isSelf = Boolean(viewer && author && String(viewer.id) === String(author.id));
  const isAdmin = Boolean(viewer && viewer.role === 'admin');

  if (!author || isSelf || isAdmin) {
    return { isSelf, isAdmin, isFollower: isSelf, isSubscriber: isSelf };
  }

  const viewerId = viewer ? viewer.id : null;
  const [isFollower, isSubscriber] = await Promise.all([
    isAcceptedFollower(viewerId, author.id),
    hasActiveSubscription(viewerId, author.id),
  ]);

  return { isSelf, isAdmin, isFollower, isSubscriber };
}

// ─── Object-level decisions ─────────────────────────────────

/**
 * Can the viewer see this author's posts at all? Governs the profile grid and
 * the "این حساب خصوصی است" empty state.
 */
export function canViewAuthorContent(author, ctx) {
  if (ctx.isSelf || ctx.isAdmin) return true;
  if (!author.is_private) return true;
  return ctx.isFollower;
}

/**
 * Decides whether the viewer gets the real media for a post.
 * Returns `{ allowed, reason }` — `reason` is null when allowed.
 * `ctx` must come from getViewerContext(viewer, author).
 */
export function canViewPost(post, author, ctx) {
  if (ctx.isSelf || ctx.isAdmin) return { allowed: true, reason: null };

  // Gate 1 — private account requires an accepted follow, whatever the post says.
  if (author.is_private && !ctx.isFollower) {
    return { allowed: false, reason: LOCK_REASON.PRIVATE_ACCOUNT };
  }

  // Gate 2 — the post's own visibility.
  switch (normalizeVisibility(post.visibility)) {
    case VISIBILITY.SUBSCRIBERS:
      return ctx.isSubscriber
        ? { allowed: true, reason: null }
        : { allowed: false, reason: LOCK_REASON.SUBSCRIBERS_ONLY };
    case VISIBILITY.FOLLOWERS:
      return ctx.isFollower
        ? { allowed: true, reason: null }
        : { allowed: false, reason: LOCK_REASON.FOLLOWERS_ONLY };
    default:
      return { allowed: true, reason: null };
  }
}

/** Convenience wrapper for a single post when the author row is not loaded yet. */
export async function canViewPostById(postId, viewer) {
  const post = await db.get('SELECT * FROM posts WHERE id = ?', [postId]);
  if (!post) return { post: null, author: null, allowed: false, reason: null };

  const author = await db.get('SELECT * FROM users WHERE id = ?', [post.user_id]);
  const ctx = await getViewerContext(viewer, author);
  const { allowed, reason } = canViewPost(post, author, ctx);
  return { post, author, ctx, allowed, reason };
}

// ─── List-level filtering (SQL) ─────────────────────────────

/**
 * SQL predicate that keeps only posts the viewer is allowed to *know about*.
 *
 * Subscribers-only posts on a public account are deliberately kept in the
 * result set as locked teasers — the viewer must see that paid content exists
 * in order to subscribe. formatPost() then strips their media. Everything the
 * viewer must not even know about (private accounts, followers-only posts) is
 * removed here instead.
 *
 * Uses correlated subqueries rather than a JOIN so it can be dropped into an
 * existing query without touching its FROM clause. Pass `postsTable` if the
 * query aliases the posts table.
 *
 * @returns {{ sql: string, params: any[] }}
 */
export function buildPostVisibilityFilter(viewer, postsTable = 'posts') {
  const viewerId = viewer ? viewer.id : null;
  const isAdmin = viewer && viewer.role === 'admin' ? 1 : 0;
  const t = postsTable;

  const acceptedFollow = `EXISTS (
    SELECT 1 FROM follows f
    WHERE f.follower_id = ? AND f.following_id = ${t}.user_id AND f.status = 'accepted'
  )`;

  const sql = `(
    ${t}.user_id = ?
    OR ? = 1
    OR (
      (
        COALESCE((SELECT is_private FROM users WHERE id = ${t}.user_id), 0) = 0
        OR ${acceptedFollow}
      )
      AND (
        ${t}.visibility IS NULL
        OR ${t}.visibility = 'public'
        OR ${t}.visibility = 'subscribers'
        OR (${t}.visibility = 'followers' AND ${acceptedFollow})
      )
    )
  )`;

  // Param order follows the placeholders above.
  const params = [viewerId, isAdmin, viewerId, viewerId];

  return { sql, params };
}
