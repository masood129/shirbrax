# 📡 مرجع کامل وب‌سرویس‌های پلتفرم شیربراکس (API Reference)

این سند مرجع دقیق و جامع تمام اندپوینت‌های RESTful سرور شیربراکس (نسخه ۱) است.

---

## 🌐 مشخصات عمومی
- **آدرس پایه (Base URL) محلی:** `http://localhost:3000/api/v1`
- **فرمت تبادل داده:** `application/json` (به جز آپلود رسانه که `multipart/form-data` است)
- **قالب کلی پاسخ‌ها (Standard Response Format):**
```json
{
  "status": "success", // یا "error"
  "message": "پیام عملیات",
  "data": { ... }
}
```

---

## 🔑 احراز هویت (Authentication)

اکثر اندپوینت‌های سامانه نیاز به توکن JWT دارند. توکن باید در هدر درخواست قرار گیرد:
```http
Authorization: Bearer <YOUR_ACCESS_TOKEN>
```

---

## ۱. ماژول احراز هویت (`/auth`)

### ۱.۱. ثبت نام کاربر جدید
* **مسیر:** `POST /api/v1/auth/register`
* **دسترسی:** عمومی
* **بدنه درخواست (JSON):**
```json
{
  "username": "user123",
  "email": "user@example.com",
  "password": "Password123",
  "name": "نام کاربر"
}
```
* **پاسخ موفق (`201 Created`):**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "username": "user123",
      "email": "user@example.com",
      "name": "نام کاربر",
      "role": "user"
    },
    "token": "eyJhbGciOi..."
  }
}
```

---

### ۱.۲. ورود به حساب کاربری
* **مسیر:** `POST /api/v1/auth/login`
* **دسترسی:** عمومی
* **بدنه درخواست:**
```json
{
  "email": "user@example.com", // یا نام کاربری در فیلد email
  "password": "Password123"
}
```
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "user": { ... },
    "token": "eyJhbGciOi..."
  }
}
```

---

### ۱.۳. دریافت اطلاعات کاربر لاگین‌شده
* **مسیر:** `GET /api/v1/auth/me`
* **دسترسی:** احراز هویت‌شده (Bearer Token)
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "username": "user123",
    "email": "user@example.com",
    "name": "نام کاربر",
    "bio": "بیوگرافی",
    "avatar_url": "/uploads/avatars/user.jpg",
    "is_private": 0,
    "role": "user"
  }
}
```

---

## ۲. ماژول پست‌ها و رسانه (`/posts`)

### ۲.۱. دریافت فید اصلی پست‌ها
* **مسیر:** `GET /api/v1/posts`
* **دسترسی:** احراز هویت‌شده
* **پارامترهای Query:**
  * `page` (پیش‌فرض: `1`): شماره صفحه
  * `per_page` (پیش‌فرض: `10`): تعداد پست در هر صفحه
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "posts": [
      {
        "id": "post-id",
        "user_id": "author-id",
        "caption": "متن پست",
        "media_type": "image", // یا "video"
        "media_url": "/uploads/posts/image.jpg", // اگر قفل باشد null است
        "visibility": "public", // "public" | "followers" | "subscribers"
        "is_locked": false,     // true برای محتوای قفل‌شده مشترکین
        "likes_count": 15,
        "comments_count": 4,
        "is_liked": true,
        "author": {
          "id": "author-id",
          "username": "author_user",
          "name": "نام نویسنده",
          "avatar_url": "/uploads/avatars/..."
        },
        "created_at": "2026-08-24T10:00:00.000Z"
      }
    ],
    "pagination": { "page": 1, "per_page": 10, "has_more": true }
  }
}
```

---

### ۲.۲. ارسال و آپلود پست جدید
* **مسیر:** `POST /api/v1/posts/upload`
* **دسترسی:** احراز هویت‌شده
* **نوع محتوا:** `multipart/form-data`
* **فیلدهای فرم:**
  * `file`: فایل تصویر یا ویدیو (اجباری)
  * `caption`: متن پست (اختیاری)
  * `visibility`: سطح دسترسی (`public` | `followers` | `subscribers` - پیش‌فرض: `public`)

---

### ۲.۳. لایک / آن‌لایک پست
* **مسیر:** `POST /api/v1/posts/:id/like`
* **دسترسی:** احراز هویت‌شده
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "liked": true,
    "likes_count": 16
  }
}
```

---

### ۲.۴. دریافت دیدگاه‌های یک پست
* **مسیر:** `GET /api/v1/posts/:id/comments`
* **دسترسی:** احراز هویت‌شده

---

### ۲.۵. ارسال دیدگاه جدید
* **مسیر:** `POST /api/v1/posts/:id/comments`
* **دسترسی:** احراز هویت‌شده
* **بدنه درخواست:**
```json
{
  "text": "دیدگاه فوق‌العاده!",
  "parent_id": null // برای پاسخ به یک کامنت، شناسه کامنت والد ارسال شود
}
```

---

### ۲.۶. صفحه کاوش و پست‌های محبوب (Explore)
* **مسیر:** `GET /api/v1/posts/explore`
* **دسترسی:** احراز هویت‌شده
* **پارامترها:** `?page=1&per_page=20`

---

## ۳. ماژول کاربران و روابط اجتماعی (`/users`)

### ۳.۱. جستجوی کاربران
* **مسیر:** `GET /api/v1/users`
* **پارامترها:** `?q=عبارت_جستجو`

---

### ۳.۲. مشاهده پروفایل کاربر
* **مسیر:** `GET /api/v1/users/:id`
* **دسترسی:** احراز هویت‌شده
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "id": "user-id",
    "username": "sara_a",
    "name": "سارا احمدی",
    "bio": "تولیدکننده محتوا",
    "avatar_url": "/uploads/avatars/...",
    "is_private": 0,
    "followers_count": 120,
    "following_count": 45,
    "posts_count": 18,
    "is_following": true,
    "follow_status": "accepted", // "none" | "pending" | "accepted"
    "subscription": {
      "enabled": true,
      "price": 50000,
      "is_active": false
    }
  }
}
```

---

### ۳.۳. فالو / آنفالو / ارسال درخواست
* **مسیر:** `POST /api/v1/users/:id/follow`
* **دسترسی:** احراز هویت‌شده
* **پاسخ موفق (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "status": "pending" // یا "following" یا "unfollowed"
  }
}
```

---

### ۳.۴. مدیریت درخواست‌های فالو (Follow Requests)
* **دریافت لیست درخواست‌های دریافتی:** `GET /api/v1/users/follow-requests`
* **تایید درخواست:** `POST /api/v1/users/follow-requests/:followerId/accept`
* **رد درخواست:** `POST /api/v1/users/follow-requests/:followerId/reject`

---

### ۳.۵. ویرایش حریم خصوصی و تنظیمات اشتراک
* **مسیر:** `PUT /api/v1/users/privacy`
* **دسترسی:** احراز هویت‌شده
* **بدنه درخواست:**
```json
{
  "is_private": 1, // 0 برای عمومی، 1 برای خصوصی
  "subscription_enabled": 1,
  "subscription_price": 75000
}
```

---

## ۴. ماژول اشتراک و درآمدزایی (`/users/:id/subscribe`)

### ۴.۱. بررسی وضعیت اشتراک
* **مسیر:** `GET /api/v1/users/:id/subscription`
* **دسترسی:** احراز هویت‌شده

### ۴.۲. خرید / تمدید اشتراک
* **مسیر:** `POST /api/v1/users/:id/subscribe`
* **بدنه درخواست:**
```json
{
  "months": 1
}
```
* **پاسخ موفق:**
```json
{
  "status": "success",
  "data": {
    "subscription_id": "sub-uuid",
    "expires_at": "2026-09-24T12:00:00.000Z",
    "payment_ref": "SIMULATED-1724490000",
    "payment_simulated": true
  }
}
```

---

## ۵. ماژول استوری‌ها (`/stories`)

### ۵.۱. دریافت استوری‌های ۲۴ ساعت گذشته
* **مسیر:** `GET /api/v1/stories`
* **دسترسی:** احراز هویت‌شده

### ۵.۲. ارسال استوری جدید
* **مسیر:** `POST /api/v1/stories`
* **نوع محتوا:** `multipart/form-data` (`file`, `caption`)

---

## ۶. ماژول پنل مدیریت (`/admin` - دسترسی ادمین)

### ۶.۱. آمار کلی سیستم
* **مسیر:** `GET /api/v1/admin/stats`
* **پاسخ موفق:**
```json
{
  "status": "success",
  "data": {
    "total_users": 150,
    "total_posts": 430,
    "total_videos": 85,
    "total_likes": 2100,
    "total_active_subscriptions": 32
  }
}
```

### ۶.۲. مسدودسازی کاربر
* **مسیر:** `POST /api/v1/admin/users/:id/ban`
* **بدنه:** `{ "banned": true, "reason": "نقض قوانین محتوا" }`

### ۶.۳. حذف اضطراری پست متخلف
* **مسیر:** `DELETE /api/v1/admin/posts/:id`

---

## ⚠️ کدهای وضعیت خطا (HTTP Status Codes)

* `200 OK`: درخواست با موفقیت انجام شد.
* `201 Created`: رکورد جدید (پست، استوری، کاربر) ایجاد گردید.
* `400 Bad Request`: ورودی‌های نامعتبر یا پارامترهای ناقص.
* `401 Unauthorized`: عدم ارسال توکن یا توکن نامعتبر/منقضی‌شده.
* `403 Forbidden`: عدم وجود مجوز دسترسی به محتوای خصوصی یا اشتراکی.
* `404 Not Found`: پست، کاربر یا منبع مورد نظر یافت نشد.
* `500 Internal Server Error`: خطای غیرمنتظره در سرور.
