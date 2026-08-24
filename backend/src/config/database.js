import sqlite3 from 'sqlite3';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dataDir = path.resolve(__dirname, '../../data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'shirbrax.db');
const rawDb = new sqlite3.Database(dbPath);

// Enable foreign keys
rawDb.run('PRAGMA foreign_keys = ON');

export const db = {
  get: (sql, params = []) =>
    new Promise((resolve, reject) => {
      rawDb.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    }),

  all: (sql, params = []) =>
    new Promise((resolve, reject) => {
      rawDb.all(sql, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    }),

  run: (sql, params = []) =>
    new Promise((resolve, reject) => {
      rawDb.run(sql, params, function (err) {
        if (err) reject(err);
        else resolve({ lastID: this.lastID, changes: this.changes });
      });
    }),

  exec: (sql) =>
    new Promise((resolve, reject) => {
      rawDb.exec(sql, (err) => {
        if (err) reject(err);
        else resolve();
      });
    }),
};

export async function initDatabase() {
  const schema = `
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      avatar TEXT,
      bio TEXT,
      role TEXT DEFAULT 'user',
      is_banned INTEGER DEFAULT 0,
      is_private INTEGER DEFAULT 0,
      subscription_enabled INTEGER DEFAULT 0,
      subscription_price INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      caption TEXT,
      media_type TEXT NOT NULL,
      media_url TEXT NOT NULL,
      thumbnail_url TEXT,
      tags TEXT,
      video_duration INTEGER,
      visibility TEXT DEFAULT 'public',
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS likes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      post_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE(user_id, post_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      post_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS comment_likes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      comment_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE(user_id, comment_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS follows (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      follower_id INTEGER NOT NULL,
      following_id INTEGER NOT NULL,
      status TEXT DEFAULT 'accepted',
      created_at TEXT NOT NULL,
      UNIQUE(follower_id, following_id),
      FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      actor_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      post_id INTEGER,
      message TEXT NOT NULL,
      is_read INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS stories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      media_url TEXT NOT NULL,
      media_type TEXT DEFAULT 'photo',
      caption TEXT,
      created_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subscriber_id INTEGER NOT NULL,
      creator_id INTEGER NOT NULL,
      amount INTEGER DEFAULT 0,
      payment_ref TEXT,
      started_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      cancelled_at TEXT,
      created_at TEXT NOT NULL,
      UNIQUE(subscriber_id, creator_id),
      FOREIGN KEY (subscriber_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_subs_lookup
      ON subscriptions (subscriber_id, creator_id, expires_at);
    CREATE INDEX IF NOT EXISTS idx_follows_status
      ON follows (follower_id, following_id, status);
    CREATE INDEX IF NOT EXISTS idx_posts_visibility
      ON posts (user_id, visibility);
  `;

  await db.exec(schema);
  await runMigrations();
}

/// Adds columns/tables introduced after the first release to an existing
/// database. Safe to run on every boot — each step checks before it acts.
async function runMigrations() {
  const added = [];

  async function addColumn(table, column, definition) {
    const cols = await db.all(`PRAGMA table_info(${table})`);
    if (cols.some((c) => c.name === column)) return;
    await db.run(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
    added.push(`${table}.${column}`);
  }

  // Account-level privacy & paid subscription settings
  await addColumn('users', 'is_private', 'INTEGER DEFAULT 0');
  await addColumn('users', 'subscription_enabled', 'INTEGER DEFAULT 0');
  await addColumn('users', 'subscription_price', 'INTEGER DEFAULT 0');

  // Per-post visibility: 'public' | 'followers' | 'subscribers'
  await addColumn('posts', 'visibility', "TEXT DEFAULT 'public'");

  // Follow approval flow: 'accepted' | 'pending'
  // Existing follows stay accepted so nobody loses access on upgrade.
  await addColumn('follows', 'status', "TEXT DEFAULT 'accepted'");
  await db.run("UPDATE follows SET status = 'accepted' WHERE status IS NULL");

  if (added.length > 0) {
    console.log(`[migration] added columns: ${added.join(', ')}`);
  }
}
