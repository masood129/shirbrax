# راهنمای سرور بک‌ند شیربراکس (ShirBrax Backend)

این پروژه بک‌ند اختصاصی و کامل برای پلتفرم اشتراک‌گذاری عکس و فیلم «شیربراکس» است که با استفاده از **Node.js**، **Express** و دیتابیس سبک و سریع **SQLite** پیاده‌سازی شده است.

---

## 🚀 نحوه راه‌اندازی و اجرا

### ۱. نصب وابستگی‌ها
```bash
cd backend
npm install
```

### ۲. اجرای سرور
برای اجرای مستقیم سرور:
```bash
npm start
```

برای اجرای در حالت توسعه (با راه‌اندازی مجدد خودکار هنگام تغییر کد):
```bash
npm run dev
```

دیتابیس به‌صورت خودکار در اولین اجرا ایجاد شده و با داده‌های اولیه نمونه (کاربران، پست‌ها و ادمین) مقداردهی اولیه (Seed) می‌شود.

---

## 🔑 حساب‌های کاربری پیش‌فرض

| نقش | ایمیل | کلمه عبور | نام کاربری | ویژگی |
|---|---|---|---|---|
| **مدیر کل (Admin)** | `admin@shirbrax.ir` | `admin123456` | `admin` | دسترسی کامل |
| **کاربر نمونه ۱** | `ali@example.com` | `123456` | `ali_m` | یک پست «فقط دنبال‌کنندگان» دارد |
| **کاربر نمونه ۲** | `sara@example.com` | `123456` | `sara_a` | **فروشنده اشتراک** (۵۰۰۰۰ تومان) + یک پست «فقط مشترکین» |
| **کاربر نمونه ۳** | `reza@example.com` | `123456` | `reza_k` | یک درخواست فالو معلق برای `maryam_h` دارد |
| **کاربر نمونه ۴** | `maryam@example.com` | `123456` | `maryam_h` | **حساب خصوصی** |

---

## 🔒 سیستم کنترل دسترسی محتوا

دسترسی به هر پست از **دو دروازه مستقل** می‌گذرد که روی هم اعمال می‌شوند:

**۱. دروازه حساب** — اگر `users.is_private = 1` باشد، دیدن پست‌ها و استوری‌ها نیازمند فالوی **تأییدشده** است.

**۲. دروازه پست** — هر پست `posts.visibility` خودش را دارد:

| مقدار | چه کسی می‌بیند |
|---|---|
| `public` | هر کسی که به حساب دسترسی دارد |
| `followers` | فقط دنبال‌کنندگان تأییدشده |
| `subscribers` | فقط مشترکین فعال (پرداخت‌کرده و منقضی‌نشده) |

قواعد رفتاری:
- پست‌های `subscribers` روی حساب عمومی به شکل **تیزر قفل‌شده** در فید و کاوش دیده می‌شوند (برای تشویق به خرید اشتراک)، اما `media_url` آن‌ها `null` است و `is_locked: true` برمی‌گردد.
- پست‌های `followers` و محتوای حساب‌های خصوصی **به‌طور کامل** از لیست‌ها حذف می‌شوند.
- صاحب پست و **ادمین** همیشه دسترسی دارند (ادمین برای امکان مدیریت محتوا).
- منطق دسترسی فقط در یک جا پیاده شده است: `src/utils/access.js`. هر مسیر جدیدی که پست برمی‌گرداند **باید** از آن استفاده کند.

### محافظت از فایل‌های رسانه

مسیر `/uploads` با middleware احراز هویت محافظت می‌شود (`src/middleware/mediaAccess.js`). حتی اگر کسی آدرس مستقیم فایل را داشته باشد، بدون دسترسی معتبر پاسخ `403` می‌گیرد. با لغو فالو یا انقضای اشتراک، دسترسی **فوراً** قطع می‌شود. آواتارها عمومی می‌مانند چون در جستجو و لیست دنبال‌کنندگان نمایش داده می‌شوند.

> ⚠️ کلاینت فلاتر برای بارگذاری رسانه باید هدر `Authorization` بفرستد — از `MediaHeaders.authHeaders()` در `lib/core/network/media_headers.dart` استفاده کنید.

---

## 📱 اتصال به کلاینت فلاتر (Flutter)

در فایل `lib/core/network/api_endpoints.dart`:
- در صورتی که با **شبیه‌ساز اندروید (Android Emulator)** تست می‌کنید:
  ```dart
  static const baseUrl = 'http://10.0.2.2:3000/api/v1';
  ```
- در صورتی که با **مرورگر وب یا دسکتاپ (Linux/macOS/Windows)** تست می‌کنید:
  ```dart
  static const baseUrl = 'http://localhost:3000/api/v1';
  ```
- در صورتی که با **گوشی واقعی** تست می‌کنید:
  آدرس IP شبکه محلی کامپیوتر خود را وارد کنید (مثلاً `http://192.168.1.100:3000/api/v1`).

---

## 📋 لیست اندپوینت‌های REST API

### 🔐 احراز هویت (Auth)
- `POST /api/v1/auth/register` - ثبت نام کاربر جدید
- `POST /api/v1/auth/login` - ورود و دریافت توکن JWT
- `GET /api/v1/auth/me` - دریافت اطلاعات کاربر وارد شده
- `POST /api/v1/auth/refresh` - تمدید توکن احراز هویت
- `POST /api/v1/auth/logout` - خروج از حساب

### 📸 پست‌ها و رسانه (Posts & Media)
- `GET /api/v1/posts` - دریافت فید پست‌ها (با قابلیت صفحه‌بندی `page` و `per_page`)
- `GET /api/v1/posts/:id` - دریافت جزئیات یک پست
- `POST /api/v1/posts/upload` - آپلود عکس/ویدیو و ایجاد پست (فیلد `visibility`: `public` | `followers` | `subscribers`)
- `POST /api/v1/posts/:id/like` - لایک و آن‌لایک پست
- `DELETE /api/v1/posts/:id` - حذف پست
- `GET /api/v1/posts/:id/comments` - دریافت نظرات یک پست
- `POST /api/v1/posts/:id/comments` - ارسال نظر جدید
- `POST /api/v1/posts/:id/comments/:commentId/like` - لایک نظر
- `GET /api/v1/posts/explore` - کاوش و جستجوی پست‌ها

### 👤 کاربران و پروفایل (Users)
- `GET /api/v1/users` - لیست و جستجوی کاربران
- `GET /api/v1/users/:id` - مشاهده اطلاعات پروفایل یک کاربر
- `GET /api/v1/users/:id/posts` - مشاهده پست‌های یک کاربر (۴۰۳ برای حساب خصوصی)
- `POST /api/v1/users/:id/follow` - فالو / آنفالو / ارسال یا لغو درخواست
- `PUT /api/v1/users/profile` - ویرایش نام، بیوگرافی و آواتار

### 🔒 حریم خصوصی و درخواست‌های فالو (Privacy)
- `PUT /api/v1/users/privacy` - تنظیم `is_private`، `subscription_enabled`، `subscription_price`
- `GET /api/v1/users/follow-requests` - لیست درخواست‌های فالوی در انتظار تأیید
- `POST /api/v1/users/follow-requests/:followerId/accept` - تأیید درخواست
- `POST /api/v1/users/follow-requests/:followerId/reject` - رد درخواست

> نکته: مسیرهای بالا **قبل از** `GET /users/:id` ثبت شده‌اند تا Express عبارت `follow-requests` را به‌عنوان شناسه کاربر تفسیر نکند.

### 💳 اشتراک (Subscriptions)
- `POST /api/v1/users/:id/subscribe` - خرید یا تمدید اشتراک (بدنه: `months`، پیش‌فرض ۱)
- `DELETE /api/v1/users/:id/subscribe` - لغو اشتراک (دسترسی تا پایان دوره پرداخت‌شده باقی می‌ماند)
- `GET /api/v1/users/:id/subscription` - وضعیت اشتراک بین شما و آن کاربر

> ⚠️ **پرداخت شبیه‌سازی شده است.** پاسخ شامل `payment_simulated: true` و یک `payment_ref` با پیشوند `SIMULATED-` است. برای اتصال درگاه واقعی (زرین‌پال/آیدی‌پی)، تأیید callback را در همان route قبل از `INSERT` اضافه کنید؛ منطق دسترسی تغییری لازم ندارد.

### 🛡️ پنل ادمین (Admin)
- `GET /api/v1/admin/stats` - دریافت آمار کلی سیستم (کاربران، پست‌ها، ویدیوها و لایک‌ها)
- `GET /api/v1/admin/users` - لیست تمام کاربران با فیلتر و جستجو
- `GET /api/v1/admin/posts` - لیست تمام پست‌ها
- `POST /api/v1/admin/users/:id/ban` - مسدودسازی یا رفع مسدودیت کاربر
- `DELETE /api/v1/admin/posts/:id` - حذف هرگونه پست نامناسب توسط ادمین

### 🔔 استوری و اعلان‌ها (Stories & Notifications)
- `GET /api/v1/stories` - دریافت استوری‌های فعال ۲۴ ساعت اخیر
- `POST /api/v1/stories` - ارسال استوری جدید
- `GET /api/v1/notifications` - دریافت لیست اعلانات
- `PATCH /api/v1/notifications/:id/read` - خوانده شدن یک اعلان
- `POST /api/v1/notifications/read-all` - خوانده شدن تمام اعلانات
