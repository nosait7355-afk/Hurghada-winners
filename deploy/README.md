# النشر — My Coach

الباك إند على **Vercel**، ونسخة الويب على **VPS بـ nginx**. الاثنان منفصلان
تماماً؛ كل واحد يُنشر وحده.

| | أين | العنوان |
|---|---|---|
| الباك إند | Vercel (`my-coach-backend`) | `https://my-coach-backend.vercel.app/api/v1` |
| نسخة الويب | VPS `76.13.63.162` | `https://coach.nosait.com` |
| تطبيق أندرويد | APK | — |

> **`/var/www/academy-web` و`app.nosait.com` تخص تطبيقاً آخر تماماً. لا تلمسها.**
> ملفات هذا التطبيق كلها تحت `/var/www/my-coach-web`.

---

## الباك إند

- مشروع Vercel `my-coach-backend` مرتبط بحساب **anosait78@gmail.com**.
- الكود على GitHub: `anosait78-star/my-coach-backend` (مجلد `backend/` مستودع
  git مستقل).
- **النشر تلقائي:** أي `git push` إلى فرع `main` ينشر على الإنتاج خلال دقيقة أو
  اثنتين. دفع أي فرع آخر يعمل نسخة معاينة (Preview) برابط منفصل فقط.
- انشر الباك إند **قبل** بناء نسخة الويب أو الـ APK التي تعتمد على تعديلاته.

---

## نسخة الويب

### التحديث المعتاد

```bash
cd frontend && flutter build web --release && cd ..
bash deploy/push-web.sh
```

بلا `sudo`: `/var/www/my-coach-web` مملوك لمستخدم `claude`.

`push-web.sh` يرفع إلى `/home/claude/my-coach-deploy/web` أولاً ثم يزامن محلياً
إلى المجلد المخدوم، فلا يمرّ رفعٌ بطيء على الملفات الحيّة. `/var/www` مملوك
لـ root، لذا لا يمكن إنشاء مجلد مؤقّت بجواره — المزامنة المحلية هي البديل.

### تحقّق بعد النشر

```bash
# هل الخادم يخدم آخر بناء فعلاً؟
md5sum frontend/build/web/main.dart.js
ssh -i ~/.ssh/claude-agent claude@76.13.63.162 'md5sum /var/www/my-coach-web/main.dart.js'

# الضغط والترويسات
curl -sI -H "Accept-Encoding: gzip" https://coach.nosait.com/main.dart.js \
  | grep -iE "content-encoding|cache-control"

# رابط مباشر (يجب أن يعيد 200 لا 404)
curl -s -o /dev/null -w "%{http_code}\n" https://coach.nosait.com/player-join-request
```

### التجهيز لمرة واحدة (تم بالفعل)

`deploy/setup-coach-site.sh` — يُشغَّل بـ `sudo` مرة واحدة فقط: ينشئ المجلد،
ويثبّت `deploy/coach.nosait.com.conf`، ويطلب شهادة certbot. إعادة تشغيله
تتوقف من نفسها إن وجدت الموقع قائماً.

### تفصيلتان في إعداد nginx لا تُحذفان

1. **`gzip_types`** — معطّلة عالمياً في `/etc/nginx/nginx.conf`، فلولا ضبطها في
   الـ server block لنزل التطبيق **~14 MB بدل ~5 MB**.
2. **ترويسات الكاش** — مخرجات Flutter للويب بلا hash في أسماء الملفات:
   `main.dart.js` يحمل الاسم نفسه كل بناء. لذا يجب أن يتحقّق من الخادم
   (`no-cache, must-revalidate`)، وإلّا بقي الزوّار على النسخة القديمة.
   `canvaskit/` وحده يُكاش أسبوعاً لأنه لا يتغيّر إلا مع نسخة Flutter.

### تشغيل محلي

```bash
cd frontend && flutter run -d web-server --web-port=3001 --web-hostname=localhost
```

المنفذ **3001** ليس اعتباطياً — `FRONTEND_URL` في بيئة Preview على Vercel
مضبوط عليه، فأي منفذ آخر يرفضه الباك إند بـ CORS.

---

## الباك إند

`backend/` مستودع git مستقل عن مستودع المشروع، ومربوط بمشروع Vercel
`my-coach-backend` تحت فريق `nosait-app`.

### نشر كود جديد

```bash
cd backend
git status          # تأكّد أن الشجرة نظيفة قبل أي شيء
vercel deploy --prod
```

### تغيير متغيّر بيئة

```bash
cd backend
vercel env ls production
vercel env rm  FRONTEND_URL production --yes
printf "https://coach.nosait.com" | vercel env add FRONTEND_URL production

# المتغيّرات لا تسري على نشرٍ قائم — لا بد من إعادة نشر.
vercel ls --prod                    # خذ رابط آخر نشر
vercel redeploy <deployment-url>
```

**استخدم `redeploy` لا `deploy` عند تغيير المتغيّرات فقط**: `redeploy` يعيد
نشر الكود المنشور نفسه بالمتغيّرات الجديدة، بينما `deploy` يرفع ما في جهازك —
وقد يحمل تعديلات غير مقصودة إلى الإنتاج.

### CORS — أكثر ما يكسر نسخة الويب

`server.js` يقرأ **`FRONTEND_URL`** (لا `ALLOWED_ORIGIN`) ويقبل **أصلاً واحداً
فقط**. عند تغيير دومين الويب لا بد من تحديثه وإعادة النشر، وإلا رفض المتصفح
كل الطلبات وظهر التطبيق شاشةً فارغة.

تطبيق الموبايل غير متأثر: التطبيقات الأصلية لا ترسل ترويسة `Origin` أصلاً،
فلا ينطبق عليها CORS.

```bash
# اختبار preflight حقيقي
curl -sI -X OPTIONS \
  -H "Origin: https://coach.nosait.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  https://my-coach-backend.vercel.app/api/v1/auth/login | grep -i access-control
```

المتوقّع: `access-control-allow-origin: https://coach.nosait.com`.

**Preview على Vercel ما زال على `http://localhost:3001`** — مقصود، للتطوير
المحلي.

### فحص سريع

```bash
curl -s https://my-coach-backend.vercel.app/health
```

المسار `/health` وليس `/api/v1/health`.

---

## الوصول إلى الخادم

```bash
ssh -i ~/.ssh/claude-agent claude@76.13.63.162
```

المستخدم `claude` يملك `sudo` **بكلمة سر**. النشر المعتاد لا يحتاجها؛ تغيير
إعداد nginx أو الشهادات يحتاجها.

```bash
sudo nginx -t && sudo systemctl reload nginx   # reload لا restart
```

`reload` لا يقطع أي موقع من المواقع الأخرى على الخادم.

---

## أشياء تُنسى فتُكلّف وقتاً

- **الحساب على Vercel:** `anosait78-star`، فريق `nosait-app`.
- **`vercel.json` في `frontend/`** بقايا خطة استضافة على Vercel لم تُستخدم.
  الاستضافة الفعلية على الـ VPS، والإعداد الساري هو
  `deploy/coach.nosait.com.conf`.
- **`frontend/build/web` مرفوع في git** عمداً — `.gitignore` يستثنيه صراحةً.
  كل بناء يغيّر ~6 MB في التاريخ.
- **لا `rsync` على ويندوز** (Git Bash)، لذا يستخدم `push-web.sh` الأمر `tar`
  عبر ssh للرفع، و`rsync` على الخادم فقط.
- **service worker في Flutter 3.44** ملف تنظيف يلغي نفسه، لا كاش أوفلاين.
  لا يعطّل تثبيت PWA — معايير Chrome تكتفي بـ HTTPS ومانيفست وأيقونات.
