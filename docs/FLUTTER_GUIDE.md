# 📱 راهنمای جامع کلاینت فلاتر (Flutter Client Guide)

این راهنما معماری، ساختار ماژول‌ها، نحوه راه‌اندازی و بیلد اپلیکیشن کلاینت **شیربراکس (ShirBrax)** را شرح می‌دهد.

---

## 📌 فهرست مطالب
- [معماری و الگوهای طراحی](#-معماری-و-الگوهای-طراحی)
- [پکیج‌های کلیدی و کتابخانه‌ها](#-پکیجهای-کلیدی-و-کتابخانهها)
- [ساختار پوشه‌بندی `lib/`](#-ساختار-پوشهبندی-lib)
- [پیکربندی اتصال به سرور (Network Config)](#-پیکربندی-اتصال-به-سرور-network-config)
- [مدیریت وضعیت و بایندینگ‌ها](#-مدیریت-وضعیت-و-بایندینگها)
- [سیستم پخش و نمایش رسانه‌های محافظت‌شده](#-سیستم-پخش-و-نمایش-رسانههای-محافظتشده)
- [اجرای اپلیکیشن در حالت توسعه](#-اجرای-اپلیکیشن-در-حالت-توسعه)
- [ساخت خروجی نهایی (Production Release Builds)](#-ساخت-خروجی-نهایی-production-release-builds)

---

## 🏗 معماری و الگوهای طراحی

کلاینت شیربراکس با معماری **Feature-First** و الگوی **Clean Architecture / MVC** پیاده‌سازی شده است:
- **Presentation Layer (Features):** صفحات (Views)، کنترلرهای GetX و ویجت‌های تعاملی هر بخش به صورت ایزوله.
- **Domain & Data Layer:** مدل‌های داده (`models`)، ارتباط با وب‌سرویس (`providers`) و لایه مخازن داده (`repositories`).
- **Core Layer:** کلاینت شبکه (`DioClient`)، بایندینگ‌های تزریق وابستگی، ذخیره‌ساز محلی (`GetStorage`) و ابزارهای سراسری.

---

## 📦 پکیج‌های کلیدی و کتابخانه‌ها

* **مدیریت وضعیت (State Management):** `get: ^4.7.2` (Reactive State & Controllers)
* **مسیریابی (Routing):** `go_router: ^15.1.2` (Declarative Routing & Deep Linking)
* **شبکه و اینترسپتورها:** `dio: ^5.8.0+1` (همراه با مدیریت توکن و خطاهای سراسری)
* **ذخیره‌سازی پایدار:** `get_storage: ^2.1.1` (کش توکن و اطلاعات کاربر)
* **پخش رسانه:**
  * تصاویر: `cached_network_image: ^3.4.1` + `photo_view: ^0.15.0`
  * ویدیو: `video_player: ^2.9.2` + `chewie: ^1.11.0`
  * انتخاب رسانه: `image_picker: ^1.1.2`
* **طراحی و رابط کاربری:** `flutter_animate`, `shimmer`, `google_fonts`, `cupertino_icons`

---

## 📂 ساختار پوشه‌بندی `lib/`

```text
lib/
├── app/
│   ├── routes/                # روت‌های GoRouter و Guardهای تغییر مسیر
│   ├── theme/                 # تم‌های رنگی تیره/روشن و استایل متون
│   └── app.dart               # ویجت ریشه MaterialApp.router
├── core/
│   ├── bindings/              # تزریق وابستگی‌های سراسری (InitialBindings)
│   ├── middleware/            # میان‌افزارهای مسیرها
│   ├── network/               # کلاینت Dio، اینترسپتورها و MediaHeaders
│   │   ├── api_endpoints.dart # آدرس‌های سرور
│   │   ├── dio_client.dart    # هندل کننده درخواست‌ها و هدرها
│   │   └── media_headers.dart # تولید هدر Authorization برای تصاویر/ویدیوها
│   ├── storage/               # مدیریت کلیدهای GetStorage (توکن و سشن)
│   └── utils/                 # توابع تاریخ جلالی/تایم‌اگو، فرمترها و اعتبارسنجی
├── data/
│   ├── models/                # کلاس‌های مدل (User, Post, Comment, Story, ...)
│   ├── providers/             # کلاس‌های برقراری ارتباط با APIها
│   └── repositories/          # تجمیع داده‌ها و مدیریت کش
├── features/                  # ماژول‌های مستقل کاربردی
│   ├── admin/                 # داشبورد مدیریت، آمار و مسدودسازی
│   ├── auth/                  # صفحات ورود، ثبت‌نام و ریکاوری
│   ├── explore/               # کاوش و جستجوی کاربران و پست‌ها
│   ├── home/                  # فید اصلی، پست‌ها و کامنت‌ها
│   ├── media/                 # پلیر ویدیو و ویوور عکس محافظت‌شده
│   ├── notifications/         # لیست اعلانات و پیام‌های سیستمی
│   ├── profile/               # پروفایل کاربری، لیست فالوئرها و درخواست‌ها
│   ├── settings/              # تنظیمات حریم خصوصی، تم و اشتراک
│   └── story/                 # مشاهده و ارسال استوری ۲۴ ساعته
├── shared/                    # دکمه‌ها، کارت‌ها، دیالوگ‌ها و لودینگ‌های مشترک
└── main.dart                  # نقطه شروع اپلیکیشن
```

---

## 🌐 پیکربندی اتصال به سرور (Network Config)

آدرس‌های سرور در فایل [api_endpoints.dart](file:///home/masoud/Documents/FlutterProject/shirbrax/lib/core/network/api_endpoints.dart) نگهداری می‌شوند:

```dart
class ApiEndpoints {
  // ۱. تست روی شبیه‌ساز استاندارد اندروید
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // ۲. تست روی مرورگر وب یا برنامه‌های دسکتاپ
  // static const String baseUrl = 'http://localhost:3000/api/v1';

  // ۳. تست روی موبایل واقعی با شبکه وای‌فای مشترک
  // static const String baseUrl = 'http://192.168.1.105:3000/api/v1';

  // ۴. محیط عملیاتی پروداکشن
  // static const String baseUrl = 'https://api.shirbrax.ir/api/v1';
}
```

---

## 🔒 سیستم پخش و نمایش رسانه‌های محافظت‌شده

به دلیل اینکه رسانه‌های سرور در مسیر `/uploads` با اعتبارسنجی توکن محافظت می‌شوند، ویجت‌های کلاینت باید هدر احراز هویت را همراه درخواست عکس/ویدیو ارسال کنند:

```dart
// نمونه نمایش عکس محافظت‌شده با CachedNetworkImage:
CachedNetworkImage(
  imageUrl: post.mediaUrl,
  httpHeaders: MediaHeaders.authHeaders(),
  placeholder: (context, url) => ShimmerLoadingWidget(),
  errorWidget: (context, url, error) => Icon(Icons.broken_image),
);
```

---

## 🏃 اجرای اپلیکیشن در حالت توسعه

۱. دریافت پکیج‌ها:
```bash
flutter pub get
```

۲. مشاهده دستگاه‌های متصل:
```bash
flutter devices
```

۳. اجرا روی دیوایس انتخابی:
```bash
flutter run
```

---

## 📦 ساخت خروجی نهایی (Production Release Builds)

### ۱. خروجی اندروید (Android APK / AppBundle)
برای انتشار در استورها (گوگل‌پلی، کافه‌بازار، مایکت):
```bash
# تولید فایل نصبی مستقیم (APK):
flutter build apk --release

# تولید باندل جهت انتشار در استور (AppBundle):
flutter build appbundle --release
```
مسیر خروجی: `build/app/outputs/flutter-apk/app-release.apk`

### ۲. خروجی وب (Web Build)
```bash
flutter build web --release
```
مسیر خروجی وب: `build/web/`

### ۳. خروجی دسکتاپ لینوکس / ویندوز
```bash
flutter build linux --release
# یا در ویندوز:
flutter build windows --release
```
