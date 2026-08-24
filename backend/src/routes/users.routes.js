import express from 'express';
import { db } from '../config/database.js';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { formatUser, formatPost } from '../utils/formatters.js';
import {
  buildPostVisibilityFilter,
  canViewAuthorContent,
  getActiveSubscription,
  getViewerContext,
} from '../utils/access.js';

const router = express.Router();

// ─── Search / List Users ──────────────────────────────────
router.get('/', optionalAuth, async (req, res) => {
  try {
    const search = req.query.search ? req.query.search.trim() : '';
    const currentUserId = req.user ? req.user.id : null;

    let rawUsers;
    if (search) {
      rawUsers = await db.all(
        `SELECT * FROM users 
         WHERE (name LIKE ? OR username LIKE ?) AND is_banned = 0 
         ORDER BY created_at DESC LIMIT 30`,
        [`%${search}%`, `%${search}%`]
      );
    } else {
      rawUsers = await db.all(
        `SELECT * FROM users WHERE is_banned = 0 ORDER BY created_at DESC LIMIT 30`
      );
    }

    const formatted = await Promise.all(
      rawUsers.map((u) => formatUser(u, req.user || null, req))
    );

    return res.json({ data: formatted });
  } catch (error) {
    console.error('List users error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت کاربران.' });
  }
});

// ─── Update Profile (Self) ────────────────────────────────
router.put('/profile', requireAuth, upload.single('avatar'), async (req, res) => {
  try {
    const { name, bio, username } = req.body;
    const userId = req.user.id;

    if (username) {
      const existing = await db.get(
        'SELECT id FROM users WHERE username = ? AND id != ?',
        [username.trim().toLowerCase(), userId]
      );
      if (existing) {
        return res.status(400).json({ message: 'این نام کاربری قبلاً توسط شخص دیگری انتخاب شده است.' });
      }
    }

    let avatarPath = req.user.avatar;
    if (req.file) {
      avatarPath = `/uploads/${req.file.filename}`;
    }

    await db.run(
      `UPDATE users 
       SET name = COALESCE(?, name),
           bio = COALESCE(?, bio),
           username = COALESCE(?, username),
           avatar = COALESCE(?, avatar)
       WHERE id = ?`,
      [
        name ? name.trim() : null,
        bio !== undefined ? bio.trim() : null,
        username ? username.trim().toLowerCase() : null,
        avatarPath,
        userId,
      ]
    );

    const updatedUser = await db.get('SELECT * FROM users WHERE id = ?', [userId]);
    const formatted = await formatUser(updatedUser, req.user, req);

    return res.json(formatted);
  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({ message: 'خطای سرور در ویرایش پروفایل.' });
  }
});

// ─── Privacy & Subscription Settings (Self) ───────────────
router.put('/privacy', requireAuth, async (req, res) => {
  try {
    const { is_private, subscription_enabled, subscription_price } = req.body;
    const userId = req.user.id;

    if (subscription_price !== undefined) {
      const price = Number(subscription_price);
      if (!Number.isInteger(price) || price < 0) {
        return res.status(400).json({ message: 'قیمت اشتراک باید یک عدد صحیح و مثبت باشد.' });
      }
    }

    const wantsSubscription =
      subscription_enabled !== undefined
        ? Boolean(subscription_enabled)
        : Boolean(req.user.subscription_enabled);
    const price =
      subscription_price !== undefined
        ? Number(subscription_price)
        : req.user.subscription_price || 0;

    if (wantsSubscription && price <= 0) {
      return res
        .status(400)
        .json({ message: 'برای فعال کردن اشتراک، قیمت باید بیشتر از صفر باشد.' });
    }

    await db.run(
      `UPDATE users
       SET is_private = COALESCE(?, is_private),
           subscription_enabled = COALESCE(?, subscription_enabled),
           subscription_price = COALESCE(?, subscription_price)
       WHERE id = ?`,
      [
        is_private !== undefined ? (is_private ? 1 : 0) : null,
        subscription_enabled !== undefined ? (subscription_enabled ? 1 : 0) : null,
        subscription_price !== undefined ? Number(subscription_price) : null,
        userId,
      ]
    );

    const updated = await db.get('SELECT * FROM users WHERE id = ?', [userId]);
    return res.json(await formatUser(updated, updated, req));
  } catch (error) {
    console.error('Update privacy error:', error);
    return res.status(500).json({ message: 'خطای سرور در ذخیره تنظیمات دسترسی.' });
  }
});

// ─── Pending Follow Requests (Self) ───────────────────────
// Registered before '/:id' so Express does not read 'follow-requests' as a user id.
router.get('/follow-requests', requireAuth, async (req, res) => {
  try {
    const rows = await db.all(
      `SELECT users.*, follows.created_at AS requested_at
       FROM follows
       JOIN users ON users.id = follows.follower_id
       WHERE follows.following_id = ? AND follows.status = 'pending'
       ORDER BY follows.created_at DESC`,
      [req.user.id]
    );

    const data = await Promise.all(
      rows.map(async (row) => ({
        ...(await formatUser(row, req.user, req)),
        requested_at: row.requested_at,
      }))
    );

    return res.json({ data, total: data.length });
  } catch (error) {
    console.error('Follow requests error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت درخواست‌ها.' });
  }
});

// ─── Accept / Reject a Follow Request ─────────────────────
router.post('/follow-requests/:followerId/:action', requireAuth, async (req, res) => {
  try {
    const { followerId, action } = req.params;

    if (action !== 'accept' && action !== 'reject') {
      return res.status(400).json({ message: 'عملیات نامعتبر است. accept یا reject.' });
    }

    const request = await db.get(
      "SELECT id FROM follows WHERE follower_id = ? AND following_id = ? AND status = 'pending'",
      [followerId, req.user.id]
    );
    if (!request) {
      return res.status(404).json({ message: 'درخواست دنبال کردن یافت نشد.' });
    }

    if (action === 'accept') {
      await db.run("UPDATE follows SET status = 'accepted' WHERE id = ?", [request.id]);
      await db.run(
        `INSERT INTO notifications (user_id, actor_id, type, message, is_read, created_at)
         VALUES (?, ?, 'follow_accepted', 'درخواست دنبال کردن شما را تأیید کرد', 0, ?)`,
        [followerId, req.user.id, new Date().toISOString()]
      );
    } else {
      await db.run('DELETE FROM follows WHERE id = ?', [request.id]);
    }

    const pendingRes = await db.get(
      "SELECT COUNT(*) as count FROM follows WHERE following_id = ? AND status = 'pending'",
      [req.user.id]
    );

    return res.json({
      status: action === 'accept' ? 'accepted' : 'rejected',
      pending_requests_count: pendingRes ? pendingRes.count : 0,
      message: action === 'accept' ? 'درخواست تأیید شد.' : 'درخواست رد شد.',
    });
  } catch (error) {
    console.error('Handle follow request error:', error);
    return res.status(500).json({ message: 'خطای سرور در پاسخ به درخواست.' });
  }
});

// ─── Get User By ID ───────────────────────────────────────
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const user = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);

    if (!user) {
      return res.status(404).json({ message: 'کاربر مورد نظر یافت نشد.' });
    }

    const formatted = await formatUser(user, req.user || null, req);
    return res.json(formatted);
  } catch (error) {
    console.error('Get user error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت کاربر.' });
  }
});

// ─── Get User Posts ───────────────────────────────────────
router.get('/:id/posts', optionalAuth, async (req, res) => {
  try {
    const userId = req.params.id;

    const author = await db.get('SELECT * FROM users WHERE id = ?', [userId]);
    if (!author) {
      return res.status(404).json({ message: 'کاربر مورد نظر یافت نشد.' });
    }

    // Account gate first — a private account exposes no post list at all.
    const ctx = await getViewerContext(req.user || null, author);
    if (!canViewAuthorContent(author, ctx)) {
      return res.status(403).json({
        message: 'این حساب خصوصی است. برای دیدن پست‌ها درخواست دنبال کردن بفرستید.',
        lock_reason: 'private_account',
        data: [],
      });
    }

    // Then per-post visibility.
    const visibility = buildPostVisibilityFilter(req.user || null);
    const rawPosts = await db.all(
      `SELECT * FROM posts
       WHERE user_id = ? AND ${visibility.sql}
       ORDER BY created_at DESC`,
      [userId, ...visibility.params]
    );

    const formatted = await Promise.all(
      rawPosts.map((p) => formatPost(p, req.user || null, req, ctx))
    );

    return res.json({ data: formatted });
  } catch (error) {
    console.error('Get user posts error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت پست‌های کاربر.' });
  }
});

// ─── Follow / Unfollow / Request to Follow ────────────────
// Public account  → follow takes effect immediately ('accepted').
// Private account → creates a 'pending' request the owner must approve.
// Calling again in any state cancels (unfollow / withdraw request).
router.post('/:id/follow', requireAuth, async (req, res) => {
  try {
    const targetUserId = parseInt(req.params.id, 10);
    const currentUserId = req.user.id;

    if (targetUserId === currentUserId) {
      return res.status(400).json({ message: 'نمی‌توانید خودتان را دنبال کنید.' });
    }

    const targetUser = await db.get('SELECT * FROM users WHERE id = ?', [targetUserId]);
    if (!targetUser) {
      return res.status(404).json({ message: 'کاربر یافت نشد.' });
    }

    const existingFollow = await db.get(
      'SELECT id, status FROM follows WHERE follower_id = ? AND following_id = ?',
      [currentUserId, targetUserId]
    );

    const now = new Date().toISOString();
    let followStatus;

    if (existingFollow) {
      await db.run('DELETE FROM follows WHERE id = ?', [existingFollow.id]);
      followStatus = 'none';
    } else {
      followStatus = targetUser.is_private ? 'pending' : 'accepted';
      await db.run(
        'INSERT INTO follows (follower_id, following_id, status, created_at) VALUES (?, ?, ?, ?)',
        [currentUserId, targetUserId, followStatus, now]
      );

      await db.run(
        `INSERT INTO notifications (user_id, actor_id, type, message, is_read, created_at)
         VALUES (?, ?, ?, ?, 0, ?)`,
        [
          targetUserId,
          currentUserId,
          followStatus === 'pending' ? 'follow_request' : 'follow',
          followStatus === 'pending'
            ? 'درخواست دنبال کردن فرستاد'
            : 'شما را دنبال کرد',
          now,
        ]
      );
    }

    const followersRes = await db.get(
      "SELECT COUNT(*) as count FROM follows WHERE following_id = ? AND status = 'accepted'",
      [targetUserId]
    );

    const messages = {
      accepted: 'کاربر دنبال شد.',
      pending: 'درخواست دنبال کردن فرستاده شد. در انتظار تأیید.',
      none: existingFollow?.status === 'pending'
        ? 'درخواست دنبال کردن لغو شد.'
        : 'دنبال کردن کاربر لغو شد.',
    };

    return res.json({
      is_following: followStatus === 'accepted',
      follow_status: followStatus,
      followers_count: followersRes ? followersRes.count : 0,
      message: messages[followStatus],
    });
  } catch (error) {
    console.error('Follow error:', error);
    return res.status(500).json({ message: 'خطای سرور در تغییر وضعیت فالو.' });
  }
});

// ─── Subscriptions ────────────────────────────────────────
// Payment is simulated for now: a POST creates/extends the subscription and
// records a fake reference. Swapping in a real gateway means verifying the
// callback here before the INSERT — the access logic does not change.
router.post('/:id/subscribe', requireAuth, async (req, res) => {
  try {
    const creatorId = parseInt(req.params.id, 10);
    const subscriberId = req.user.id;

    if (creatorId === subscriberId) {
      return res.status(400).json({ message: 'نمی‌توانید مشترک خودتان شوید.' });
    }

    const creator = await db.get('SELECT * FROM users WHERE id = ?', [creatorId]);
    if (!creator) {
      return res.status(404).json({ message: 'کاربر یافت نشد.' });
    }
    if (!creator.subscription_enabled) {
      return res
        .status(400)
        .json({ message: 'این کاربر اشتراک فعالی برای فروش ندارد.' });
    }

    const months = Math.min(12, Math.max(1, parseInt(req.body.months, 10) || 1));
    const amount = (creator.subscription_price || 0) * months;
    const now = new Date();
    const nowIso = now.toISOString();

    const existing = await db.get(
      'SELECT * FROM subscriptions WHERE subscriber_id = ? AND creator_id = ?',
      [subscriberId, creatorId]
    );

    // Renewing an active subscription extends it; an expired or cancelled one
    // restarts from today.
    const activeUntil =
      existing && !existing.cancelled_at && new Date(existing.expires_at) > now
        ? new Date(existing.expires_at)
        : now;
    const expiresAt = new Date(activeUntil.getTime());
    expiresAt.setMonth(expiresAt.getMonth() + months);

    // TODO: replace with a real gateway verification (Zarinpal/IDPay).
    const paymentRef = `SIMULATED-${subscriberId}-${creatorId}-${now.getTime()}`;

    if (existing) {
      await db.run(
        `UPDATE subscriptions
         SET amount = ?, payment_ref = ?, started_at = ?, expires_at = ?, cancelled_at = NULL
         WHERE id = ?`,
        [amount, paymentRef, nowIso, expiresAt.toISOString(), existing.id]
      );
    } else {
      await db.run(
        `INSERT INTO subscriptions
           (subscriber_id, creator_id, amount, payment_ref, started_at, expires_at, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [subscriberId, creatorId, amount, paymentRef, nowIso, expiresAt.toISOString(), nowIso]
      );
    }

    await db.run(
      `INSERT INTO notifications (user_id, actor_id, type, message, is_read, created_at)
       VALUES (?, ?, 'subscription', 'مشترک شما شد', 0, ?)`,
      [creatorId, subscriberId, nowIso]
    );

    return res.status(201).json({
      is_subscribed: true,
      expires_at: expiresAt.toISOString(),
      amount,
      months,
      payment_ref: paymentRef,
      payment_simulated: true,
      message: `اشتراک شما تا ${expiresAt.toLocaleDateString('fa-IR')} فعال شد.`,
    });
  } catch (error) {
    console.error('Subscribe error:', error);
    return res.status(500).json({ message: 'خطای سرور در ثبت اشتراک.' });
  }
});

// Cancel — keeps access until the paid period ends, matching how real
// subscriptions behave. Set expires_at to now instead if you want it immediate.
router.delete('/:id/subscribe', requireAuth, async (req, res) => {
  try {
    const creatorId = parseInt(req.params.id, 10);
    const subscription = await db.get(
      'SELECT * FROM subscriptions WHERE subscriber_id = ? AND creator_id = ?',
      [req.user.id, creatorId]
    );

    if (!subscription || subscription.cancelled_at) {
      return res.status(404).json({ message: 'اشتراک فعالی یافت نشد.' });
    }

    await db.run('UPDATE subscriptions SET cancelled_at = ? WHERE id = ?', [
      new Date().toISOString(),
      subscription.id,
    ]);

    return res.json({
      is_subscribed: false,
      access_until: subscription.expires_at,
      message: 'اشتراک لغو شد. دسترسی شما تا پایان دوره پرداخت‌شده باقی می‌ماند.',
    });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    return res.status(500).json({ message: 'خطای سرور در لغو اشتراک.' });
  }
});

// Subscription state between the caller and one creator.
router.get('/:id/subscription', requireAuth, async (req, res) => {
  try {
    const creatorId = parseInt(req.params.id, 10);
    const creator = await db.get('SELECT * FROM users WHERE id = ?', [creatorId]);
    if (!creator) {
      return res.status(404).json({ message: 'کاربر یافت نشد.' });
    }

    const active = await getActiveSubscription(req.user.id, creatorId);
    return res.json({
      is_subscribed: Boolean(active),
      expires_at: active ? active.expires_at : null,
      subscription_enabled: Boolean(creator.subscription_enabled),
      subscription_price: creator.subscription_price || 0,
    });
  } catch (error) {
    console.error('Get subscription error:', error);
    return res.status(500).json({ message: 'خطای سرور در دریافت وضعیت اشتراک.' });
  }
});

export default router;
