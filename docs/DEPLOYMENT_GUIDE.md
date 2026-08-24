# 🚀 راهنمای جامع استقرار در محیط عملیاتی (Production Deployment Guide)

این راهنما مراحل کامل آماده‌سازی سرور لینوکس، استقرار بک‌اند Node.js شیربراکس، تنظیم وب‌سرور معکوس Nginx، گواهی امنیتی SSL و بیلد پروداکشن کلاینت فلاتر را به صورت گام به گام شرح می‌دهد.

---

## 📌 فهرست مطالب
- [۱. پیش‌نیازهای سرور](#۱-پیشنیازهای-سرور)
- [۲. آماده‌سازی محیط و نصب بسته‌ها](#۲-آمادهسازی-محیط-و-نصب-بستهها)
- [۳. پیکربندی و راه‌اندازی بک‌اند با PM2](#۳-پیکربندی-و-راهاندازی-بکاند-با-pm2)
- [۴. پیکربندی وب‌سرور Nginx و پروکسی معکوس](#۴-پیکربندی-وبسرور-nginx-و-پروکسی-معکوس)
- [۵. فعال‌سازی گواهی امنیتی رایگان SSL (Certbot)](#۵-فعالسازی-گواهی-امنیتی-رایگان-ssl-certbot)
- [۶. پشتیبان‌گیری منظم (Backup Strategy)](#۶-پشتیبانگیری-منظم-backup-strategy)
- [۷. استقرار نسخه وب و اپلیکیشن فلاتر](#۷-استقرار-نسخه-وب-و-اپلیکیشن-فلاتر)

---

## ۱. پیش‌نیازهای سرور

* **سرور مجازی (VPS) یا سرور اختصاصی:** سیستم‌عامل پیشنهادی Ubuntu 22.04 LTS یا 24.04 LTS
* **حداقل مشخصات سخت‌افزاری:** ۱ گیگابایت رم، ۱ هسته CPU، ۲۰ گیگابایت فضای SSD
* **دامنه اینترنتی (Domain):** دارای رکورد DNS نوع `A` که به آی‌پی سرور اشاره کند (مثال: `api.shirbrax.ir` و `app.shirbrax.ir`).

---

## ۲. آماده‌سازی محیط و نصب بسته‌ها

با دسترسی SSH به سرور متصل شده و بسته‌های مورد نیاز را نصب کنید:

```bash
# بروزرسانی مخازن
sudo apt update && sudo apt upgrade -y

# نصب ابزارهای پایه و Nginx
sudo apt install -y curl git ufw nginx build-essential

# نصب Node.js نسخه 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# بررسی نسخه نصب شده
node -v # باید v20.x باشد
npm -v

# نصب سراسری PM2
sudo npm install -g pm2
```

پیکربندی فایروال (UFW):
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

## ۳. پیکربندی و راه‌اندازی بک‌اند با PM2

۱. کلون کردن پروژه یا آپلود فایل‌های پوشه `backend` در مسیر `/var/www/shirbrax/backend`:

```bash
sudo mkdir -p /var/www/shirbrax
sudo chown -R $USER:$USER /var/www/shirbrax
cd /var/www/shirbrax

# کپی سورس یا git clone
# cd backend
```

۲. نصب پکیج‌های پروداکشن:
```bash
cd /var/www/shirbrax/backend
npm install --omit=dev
```

۳. ساخت و تنظیم فایل `.env` پروداکشن:
```bash
nano .env
```
محتوای `.env`:
```env
PORT=3000
NODE_ENV=production
JWT_SECRET=super_strong_random_secret_key_prod_9876543210!@#$%
JWT_EXPIRES_IN=30d
BASE_URL=https://api.shirbrax.ir
```

۴. راه‌اندازی پروسس سرور با PM2:
```bash
pm2 start src/server.js --name "shirbrax-api"

# تنظیم اجرای خودکار در صورت روشن/ریست شدن سرور:
pm2 save
pm2 startup
# سپس دستوری که خروجی نمایش می‌دهد را با sudo کپی و اجرا کنید
```

---

## ۴. پیکربندی وب‌سرور Nginx و پروکسی معکوس

یک فایل کانفیگ جدید برای دامنه API ایجاد کنید:

```bash
sudo nano /etc/nginx/sites-available/shirbrax-api.conf
```

محتوای فایل:
```nginx
server {
    listen 80;
    server_name api.shirbrax.ir;

    # حداکثر حجم فایل آپلودی به سرور (مثلاً 50 مگابایت)
    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # تنظیم تایم‌اوت برای آپلود فایل‌های حجیم
        proxy_connect_timeout 90s;
        proxy_send_timeout 90s;
        proxy_read_timeout 90s;
    }
}
```

فعال‌سازی و تست Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/shirbrax-api.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## ۵. فعال‌سازی گواهی امنیتی رایگان SSL (Certbot)

برای فعال‌سازی پروتکل امن `HTTPS` از ابزار Let's Encrypt Certbot استفاده کنید:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.shirbrax.ir
```

سرتبوت به صورت خودکار فایل‌های کانفیگ Nginx را جهت ریدایرکت خودکار به HTTPS بروزرسانی کرده و تایمر تمدید خودکار ۹۰ روزه را فعال می‌سازد.

---

## ۶. پشتیبان‌گیری منظم (Backup Strategy)

داده‌های مهم شامل فایل پایگاه داده (`data/database.sqlite`) و رسانه‌های آپلودشده کاربران (`uploads/`) می‌باشند.

ایجاد اسکریپت بکاپ‌گیری خودکار:
```bash
mkdir -p /home/$USER/backups
sudo nano /home/$USER/backup_shirbrax.sh
```

محتوای اسکریپت:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/$USER/backups"
SOURCE_DIR="/var/www/shirbrax/backend"

# ایجاد فایل فشرده
tar -czf $BACKUP_DIR/shirbrax_backup_$DATE.tar.gz -C $SOURCE_DIR data uploads

# حذف بکاپ‌های قدیمی‌تر از ۱۴ روز
find $BACKUP_DIR -type f -name "shirbrax_backup_*.tar.gz" -mtime +14 -exec rm {} \;
```

دادن مجوز اجرا و تنظیم در Crontab سرور:
```bash
chmod +x /home/$USER/backup_shirbrax.sh
crontab -e
```
افزودن خط زیر جهت اجرای روزانه رأس ساعت ۳:۰۰ بامداد:
```text
0 3 * * * /home/$USER/backup_shirbrax.sh >/dev/null 2>&1
```

---

## ۷. استقرار نسخه وب و اپلیکیشن فلاتر

### استقرار وب کلاینت در Nginx
۱. در سیستم محلی بیلد وب را بسازید:
```bash
flutter build web --release
```
۲. پوشه `build/web/` را به مسیر `/var/www/shirbrax/web` سرور منتقل کنید.
۳. در Nginx یک بلاک سرور برای دامنه وب (مثلاً `app.shirbrax.ir`) با ریشه `/var/www/shirbrax/web` تعریف کرده و برای روتینگ GoRouter، خط زیر را قرار دهید:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```
