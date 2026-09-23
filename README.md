# عازل (Aazil) - عارض وسائط معزول أمنيًا | Sandboxed Media Viewer

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org)
[![Security](https://img.shields.io/badge/Security-Seccomp--BPF-red?style=for-the-badge&logo=shield)](https://github.com)
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Mobile%20%7C%20Web-blue?style=for-the-badge)](https://github.com)

**[العربية](#-عازل---عارض-وسائط-معزول-أمنيا) • [English](#-aazil---sandboxed-media-viewer)**

</div>

---

## عازل - عارض وسائط معزول أمنيًا

تطبيق **عازل** هو بيئة عمل آمنة لمعاينة وتشغيل الصور ومقاطع الفيديو المشبوهة أو غير الموثوقة بأمان تام داخل بيئة عزل صارمة (Sandbox) على مستوى نظام التشغيل، لحماية جهاز المضيف من استغلال ثغرات برامج فك الترميز (Media Codecs) والبرمجيات الخبيثة.

---

### 📸 لقطات الشاشة (Screenshots)

#### 1. الصفحة التعريفية
<img width="1920" height="1040" alt="الصفحة التعريفية" src="https://github.com/user-attachments/assets/3bb11867-02fb-4304-aab4-f9a8f5e1457a" />

#### 2. الواجهة الرئيسية
<img width="1920" height="1040" alt="الواجهة الرئيسية" src="https://github.com/user-attachments/assets/bee4f870-57cb-4dff-b8c1-add2b2a5b36b" />

#### 3. معرض الصور المعزول
<img width="1920" height="1040" alt="معرض الصور" src="https://github.com/user-attachments/assets/59ce5f09-90c3-4337-ae26-fff9a252fc1e" />

#### 4. معرض الفيديو وقائمة التشغيل المعزولة
<img width="1920" height="1040" alt="معرض الفيديو" src="https://github.com/user-attachments/assets/99f0b8fe-4ebd-46fc-9eae-f7d0c434e9e4" />

---

### ✨ المميزات الرئيسية

- **🛡️ عزل أمني على مستوى النظام (OS-Level Sandbox)**:
  - تشغيل وفك ترميز الوسائط داخل بيئات عزل مغلقة ومنفصلة.
  - دعم مرشحات نداءات النظام الصارمة (`Seccomp-BPF` على لينكس).
  - عزل العمليات بصلاحيات دنيا (`Unprivileged / Low-Integrity`).
- **🚫 حظر الاتصال بالشبكة تماماً (Network Denied)**:
  - منع أي محاولة للاتصال بالإنترنت لمنع تسريب البيانات أو الاتصال بخوادم التحكم والسيطرة (C2).
- **📁 تقييد الوصول لنظام الملفات (Filesystem Restricted)**:
  - تشغيل الوسائط عبر نسخ معزولة ومؤقتة، ومنع الوصول لأي ملفات خارج النطاق المصرح به.
- **🖼️ معرض صور متقدم (Sandboxed Image Gallery)**:
  - دعم التنقل السلس بين الصور عبر اللمس أو أسهم لوحة المفاتيح.
  - عزل آمن لكل صورة على حدة مع تنظيف الذاكرة المؤقتة.
- **🎬 مشغل فيديو وقوائم تشغيل متطورة (Sandboxed Video Player)**:
  - قراءة دقيقة لمدة الفيديو (`Metadata Parsing`).
  - تحكم كامل بمستوى الصوت، كتم الصوت، والتكرار (`Off / One / All`).
  - تشغيل تلقائي وتسلسل آمن لقوائم التشغيل.
- **🧪 اختبارات أمنية مدمجة (Sandbox Security Verification)**:
  - إمكانية تشغيل اختبارات تحقق أمني للتأكد من حظر محاولات الاتصال بالشبكة أو الوصول لنظام الملفات.
- **🌐 دعم متعدد المنصات واللغات**:
  - واجهات مخصصة للحاسوب (Desktop: Linux, macOS, Windows)، الهواتف (Mobile: Android, iOS)، والويب (Web).
  - دعم كامل للغتين العربية والإنجليزية.
  - دعم الوضع الداكن (Dark Mode) والفاتح (Light Mode).

---

### 🚀 التشغيل والتطوير

#### المتطلبات المسبقة
- تثبيت [Flutter SDK](https://flutter.dev) (الإصدار 3.13.4 أو أحدث).
- بيئة تطوير مناسبة للمنصة المستهدفة (مثل أدوات بناء لينكس: `build-essential`, `cmake`, `libmpv-dev`).

#### خطوات التشغيل
1. استنساخ المستودع والدخول للمجلد:
   ```bash
   cd aazil
   ```

2. تثبيت الحزم والاعتماديات:
   ```bash
   flutter pub get
   ```

3. توليد ملفات الترجمة:
   ```bash
   flutter gen-l10n
   ```

4. تشغيل التطبيق:
   ```bash
   # للتشغيل على سطح المكتب (لينكس)
   flutter run -d linux

   # للتشغيل على الويب
   flutter run -d chrome
   ```

---

<br/>

## Aazil - Sandboxed Media Viewer

**Aazil** (عازل) is a secure, sandboxed media workspace designed to inspect and play untrusted or suspicious images and videos safely inside an OS-level isolated sandbox. It protects your host machine against malicious payloads, parser vulnerabilities, and codec exploitation.

---

### 📸 Screenshots

#### 1. Landing & Onboarding Screen
<img width="1920" height="1040" alt="Landing Screen" src="https://github.com/user-attachments/assets/3bb11867-02fb-4304-aab4-f9a8f5e1457a" />

#### 2. Main Workspace & Dashboard
<img width="1920" height="1040" alt="Main Workspace" src="https://github.com/user-attachments/assets/bee4f870-57cb-4dff-b8c1-add2b2a5b36b" />

#### 3. Sandboxed Multi-Image Gallery
<img width="1920" height="1040" alt="Multi-Image Gallery" src="https://github.com/user-attachments/assets/59ce5f09-90c3-4337-ae26-fff9a252fc1e" />

#### 4. Sandboxed Video Playlist & Player
<img width="1920" height="1040" alt="Video Playlist Player" src="https://github.com/user-attachments/assets/99f0b8fe-4ebd-46fc-9eae-f7d0c434e9e4" />

---

### ✨ Key Features

- **🛡️ OS-Level Sandboxing**:
  - Media preview and decoding execute inside strictly isolated sandboxes.
  - Linux `Seccomp-BPF` syscall filtering and namespace isolation.
  - Low-integrity / unprivileged process execution.
- **🚫 Network Access Denied**:
  - Network sockets and external traffic are strictly blocked to eliminate data exfiltration and C2 beaconing.
- **📁 Restricted Filesystem**:
  - Whitelisted temporary copies only; prevents arbitrary filesystem traversal or host disk modification.
- **🖼️ Multi-Image Gallery**:
  - Smooth navigation with keyboard arrows and touch swipe gestures.
  - Fresh sandbox boundary execution per image with automated cache purging.
- **🎬 Multi-Video Playlist & Player**:
  - Real container header parsing (`MP4/MOV mvhd`, `WebM/MKV EBML`, `AVI`) for accurate video duration tracking.
  - Full playback controls: seek bar, volume/mute, repeat modes (`Off`, `One`, `All`), and automatic advance.
- **🧪 Built-in Security Diagnostics**:
  - Built-in verification tests to confirm sandbox enforcement (network blocking and out-of-whitelist access attempts).
- **🌐 Responsive Multi-Platform & Multilingual**:
  - Tailored UI implementations for Desktop (Linux, macOS, Windows), Mobile (Android, iOS), and Web.
  - Complete Arabic and English localization with Dark and Light theme support.

---

### 🚀 Getting Started

#### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.13.4 or higher).
- Target platform build tools (e.g., for Linux: `build-essential`, `cmake`, `libmpv-dev`).

#### Installation & Run
1. Navigate to the project directory:
   ```bash
   cd aazil
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Generate localization files:
   ```bash
   flutter gen-l10n
   ```

4. Run the app:
   ```bash
   # Run on Linux Desktop
   flutter run -d linux

   # Run on Web
   flutter run -d chrome
   ```

---

### 📄 License

This project is licensed under the terms defined in the project repository.
