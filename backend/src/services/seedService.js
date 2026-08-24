import bcrypt from 'bcryptjs';
import { db, initDatabase } from '../config/database.js';

export async function seedDatabase() {
  await initDatabase();

  const userCount = await db.get('SELECT COUNT(*) as count FROM users');
  if (userCount && userCount.count > 0) {
    console.log('Database already has data. Skipping seed.');
    return;
  }

  console.log('Seeding database with initial data...');

  const defaultPasswordHash = await bcrypt.hash('123456', 10);
  const adminPasswordHash = await bcrypt.hash('admin123456', 10);

  const now = new Date();

  // 1. Insert Users
  const users = [
    {
      name: 'مدیر سیستم',
      username: 'admin',
      email: 'admin@shirbrax.ir',
      password: adminPasswordHash,
      role: 'admin',
      avatar: 'https://i.pravatar.cc/150?img=60',
      bio: 'حساب رسمی مدیریت سامانه شیربراکس 🛡️',
      created_at: new Date(now.getTime() - 90 * 86400000).toISOString(),
    },
    {
      name: 'علی محمدی',
      username: 'ali_m',
      email: 'ali@example.com',
      password: defaultPasswordHash,
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=3',
      bio: 'عاشق عکاسی و سفر 📸',
      created_at: new Date(now.getTime() - 60 * 86400000).toISOString(),
    },
    {
      name: 'سارا احمدی',
      username: 'sara_a',
      email: 'sara@example.com',
      password: defaultPasswordHash,
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=5',
      bio: 'هنر، طراحی و انیمیشن 🎨',
      // Paid creator — sells a monthly subscription.
      subscription_enabled: 1,
      subscription_price: 50000,
      created_at: new Date(now.getTime() - 45 * 86400000).toISOString(),
    },
    {
      name: 'رضا کریمی',
      username: 'reza_k',
      email: 'reza@example.com',
      password: defaultPasswordHash,
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=7',
      bio: 'طبیعت‌گردی و کوه‌نوردی 🏔️',
      created_at: new Date(now.getTime() - 30 * 86400000).toISOString(),
    },
    {
      name: 'مریم حسینی',
      username: 'maryam_h',
      email: 'maryam@example.com',
      password: defaultPasswordHash,
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=9',
      bio: 'کتاب، موسیقی و قهوه ☕',
      // Private account — follows must be approved before content is visible.
      is_private: 1,
      created_at: new Date(now.getTime() - 15 * 86400000).toISOString(),
    },
  ];

  const userIds = {};
  for (const u of users) {
    const res = await db.run(
      `INSERT INTO users
         (name, username, email, password, role, avatar, bio, is_banned,
          is_private, subscription_enabled, subscription_price, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)`,
      [
        u.name,
        u.username,
        u.email,
        u.password,
        u.role,
        u.avatar,
        u.bio,
        u.is_private || 0,
        u.subscription_enabled || 0,
        u.subscription_price || 0,
        u.created_at,
      ]
    );
    userIds[u.username] = res.lastID;
  }

  // 2. Insert Follows — [follower, following, status]
  // maryam_h is private, so follows pointing at her carry a status.
  const follows = [
    [userIds.ali_m, userIds.sara_a, 'accepted'],
    [userIds.ali_m, userIds.reza_k, 'accepted'],
    [userIds.sara_a, userIds.ali_m, 'accepted'],
    [userIds.sara_a, userIds.maryam_h, 'accepted'],
    [userIds.reza_k, userIds.ali_m, 'accepted'],
    [userIds.maryam_h, userIds.ali_m, 'accepted'],
    [userIds.maryam_h, userIds.sara_a, 'accepted'],
    // A request waiting for maryam_h to approve — exercises the request flow.
    [userIds.reza_k, userIds.maryam_h, 'pending'],
  ];

  for (const [follower, following, status] of follows) {
    await db.run(
      'INSERT INTO follows (follower_id, following_id, status, created_at) VALUES (?, ?, ?, ?)',
      [
        follower,
        following,
        status,
        new Date(now.getTime() - 10 * 86400000).toISOString(),
      ]
    );
  }

  // 3. Insert Posts
  const posts = [
    {
      user_id: userIds.ali_m,
      caption: 'غروب زیبای دیروز در کویر مرنجاب 🌅 جای همگی خالی',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/desert_sunset/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/desert_sunset/400/300',
      tags: JSON.stringify(['طبیعت', 'غروب', 'کویر', 'عکاسی']),
      created_at: new Date(now.getTime() - 2 * 3600000).toISOString(),
    },
    {
      user_id: userIds.sara_a,
      caption: 'لحظات فوق‌العاده با دوستان صمیمی در کافه 💕',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/friends_cafe/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/friends_cafe/400/300',
      tags: JSON.stringify(['دوستی', 'کافه', 'خاطره']),
      created_at: new Date(now.getTime() - 5 * 3600000).toISOString(),
    },
    {
      user_id: userIds.ali_m,
      caption: 'ویدیو کوه‌نوردی و صعود به قله دماوند 🏔️ همراه با تیم باحال',
      media_type: 'video',
      media_url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      thumbnail_url: 'https://picsum.photos/seed/damavand_peak/400/300',
      tags: JSON.stringify(['ورزش', 'کوهنوردی', 'دماوند', 'طبیعت']),
      video_duration: 90,
      created_at: new Date(now.getTime() - 24 * 3600000).toISOString(),
    },
    {
      user_id: userIds.reza_k,
      caption: 'آشپزی در طبیعت در دل جنگل‌های شمال 🍜 چای آتشی فراموش نشه!',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/forest_cooking/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/forest_cooking/400/300',
      tags: JSON.stringify(['آشپزی', 'طبیعت', 'شمال']),
      created_at: new Date(now.getTime() - 48 * 3600000).toISOString(),
    },
    {
      user_id: userIds.maryam_h,
      caption: 'یک بعدازظهر پاییزی همراه با یک فنجان قهوه و کتاب خوب ☕📚',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/autumn_coffee/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/autumn_coffee/400/300',
      tags: JSON.stringify(['کتاب', 'قهوه', 'آرامش']),
      created_at: new Date(now.getTime() - 72 * 3600000).toISOString(),
    },
    // ─── Access-controlled demo posts ─────────────────────────
    // sara_a sells subscriptions: this one shows as a locked teaser to
    // everyone who has not paid.
    {
      user_id: userIds.sara_a,
      caption: 'پشت صحنه پروژه جدید — فقط برای مشترکین ویژه 🎬',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/behind_scenes/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/behind_scenes/400/300',
      tags: JSON.stringify(['طراحی', 'اختصاصی']),
      visibility: 'subscribers',
      created_at: new Date(now.getTime() - 6 * 3600000).toISOString(),
    },
    // ali_m restricts this one to accepted followers.
    {
      user_id: userIds.ali_m,
      caption: 'عکس‌های خانوادگی سفر — فقط دنبال‌کنندگان 👨‍👩‍👧',
      media_type: 'photo',
      media_url: 'https://picsum.photos/seed/family_trip/1200/800',
      thumbnail_url: 'https://picsum.photos/seed/family_trip/400/300',
      tags: JSON.stringify(['خانواده', 'سفر']),
      visibility: 'followers',
      created_at: new Date(now.getTime() - 8 * 3600000).toISOString(),
    },
  ];

  const postIds = [];
  for (const p of posts) {
    const res = await db.run(
      `INSERT INTO posts (user_id, caption, media_type, media_url, thumbnail_url, tags, video_duration, visibility, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        p.user_id,
        p.caption,
        p.media_type,
        p.media_url,
        p.thumbnail_url,
        p.tags,
        p.video_duration || null,
        p.visibility || 'public',
        p.created_at,
      ]
    );
    postIds.push(res.lastID);
  }

  // 4. Insert Likes
  const likes = [
    [userIds.sara_a, postIds[0]],
    [userIds.reza_k, postIds[0]],
    [userIds.maryam_h, postIds[0]],
    [userIds.ali_m, postIds[1]],
    [userIds.maryam_h, postIds[1]],
    [userIds.sara_a, postIds[2]],
    [userIds.reza_k, postIds[2]],
    [userIds.ali_m, postIds[3]],
    [userIds.sara_a, postIds[4]],
  ];

  for (const [userId, postId] of likes) {
    await db.run('INSERT INTO likes (user_id, post_id, created_at) VALUES (?, ?, ?)', [
      userId,
      postId,
      new Date(now.getTime() - 3600000).toISOString(),
    ]);
  }

  // 5. Insert Comments
  const comments = [
    {
      post_id: postIds[0],
      user_id: userIds.sara_a,
      text: 'عکس فوق‌العاده‌ای است! نور غروب عالی افتاده 😍',
      created_at: new Date(now.getTime() - 90 * 60000).toISOString(),
    },
    {
      post_id: postIds[0],
      user_id: userIds.reza_k,
      text: 'کدوم منطقه رفتی علی جان؟ هوا چطور بود؟',
      created_at: new Date(now.getTime() - 60 * 60000).toISOString(),
    },
    {
      post_id: postIds[1],
      user_id: userIds.ali_m,
      text: 'همیشه به خوشی و شادی 🌟',
      created_at: new Date(now.getTime() - 120 * 60000).toISOString(),
    },
    {
      post_id: postIds[2],
      user_id: userIds.maryam_h,
      text: 'ماشاالله به این همت! دمتون گرم 👏',
      created_at: new Date(now.getTime() - 180 * 60000).toISOString(),
    },
  ];

  for (const c of comments) {
    await db.run(
      'INSERT INTO comments (post_id, user_id, text, created_at) VALUES (?, ?, ?, ?)',
      [c.post_id, c.user_id, c.text, c.created_at]
    );
  }

  // 6. Insert Notifications
  const notifications = [
    {
      user_id: userIds.ali_m,
      actor_id: userIds.sara_a,
      type: 'like',
      post_id: postIds[0],
      message: 'پست شما را لایک کرد',
      is_read: 0,
      created_at: new Date(now.getTime() - 10 * 60000).toISOString(),
    },
    {
      user_id: userIds.ali_m,
      actor_id: userIds.reza_k,
      type: 'comment',
      post_id: postIds[0],
      message: 'نظر گذاشت: کدوم منطقه رفتی علی جان؟',
      is_read: 0,
      created_at: new Date(now.getTime() - 30 * 60000).toISOString(),
    },
    {
      user_id: userIds.ali_m,
      actor_id: userIds.maryam_h,
      type: 'follow',
      message: 'شما را دنبال کرد',
      is_read: 1,
      created_at: new Date(now.getTime() - 120 * 60000).toISOString(),
    },
  ];

  for (const n of notifications) {
    await db.run(
      `INSERT INTO notifications (user_id, actor_id, type, post_id, message, is_read, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [n.user_id, n.actor_id, n.type, n.post_id || null, n.message, n.is_read, n.created_at]
    );
  }

  console.log('Seeding completed successfully!');
}

if (process.argv[1] && process.argv[1].endsWith('seedService.js')) {
  seedDatabase().then(() => {
    console.log('Done.');
    process.exit(0);
  });
}
