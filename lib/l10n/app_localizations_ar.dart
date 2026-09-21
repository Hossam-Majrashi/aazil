// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'عازل';

  @override
  String get appSubtitle => 'عارض وسائط معزول أمنيًا';

  @override
  String get appDescription =>
      'معاينة وتشغيل الصور ومقاطع الفيديو المشبوهة بأمان تام داخل بيئة عزل على مستوى نظام التشغيل. حماية جهازك من استغلال ثغرات الترميز والبرمجيات الخبيثة.';

  @override
  String get splashContinue => 'متابعة';

  @override
  String get selectLanguage => 'اختيار اللغة';

  @override
  String get languageSubtitle => 'اختر لغة واجهة التطبيق المفضلة';

  @override
  String get selectTheme => 'اختيار المظهر';

  @override
  String get themeSubtitle => 'اختر مظهر وشكل التطبيق';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get homeTitle => 'مساحة عمل عازل';

  @override
  String get createProject => 'إنشاء مشروع جديد';

  @override
  String get createProjectDesc =>
      'فتح مجلد أو اختيار ملفات وسائط لمعاينتها بأمان داخل جلسة معزولة.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsDesc =>
      'معاينة خصائص العزل الأمني، حالة بيئة العزل، وتشخيص النظام.';

  @override
  String get about => 'عن عازل';

  @override
  String get sandboxStatus => 'محرك العزل الأمني';

  @override
  String get sandboxActive => 'مفعّل ومفروض بنجاح';

  @override
  String get securityGuarantees => 'الضمانات الأمنية';

  @override
  String get networkDenied => 'الاتصال بالشبكة: محظور نهائيًا';

  @override
  String get fsRestricted => 'نظام الملفات: مقيّد (نسخة معزولة ومؤقتة فقط)';

  @override
  String get syscallFilter => 'مرشح نداءات النظام: Seccomp-BPF نشط';

  @override
  String get processIsolation =>
      'عزل العمليات: عديمة الامتيازات / منخفضة الصلاحية';

  @override
  String get recentProjects => 'الجلسات الآمنة الأخيرة';

  @override
  String get noProjectsYet => 'لا توجد مشاريع سابقة. أنشئ جلسة جديدة للبدء.';

  @override
  String get openFolder => 'فتح مجلد';

  @override
  String get selectFiles => 'اختيار ملفات وسائط';

  @override
  String mediaFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات وسائط',
      two: 'ملفان',
      one: 'ملف وسائط واحد',
      zero: 'لا توجد ملفات',
    );
    return '$_temp0';
  }

  @override
  String get sandboxedPreview => 'معاينة معزولة';

  @override
  String get previewLoading => 'جاري تهيئة بيئة العزل المغلقة...';

  @override
  String get previewRendering =>
      'جاري فك ترميز الوسائط داخل الصندوق المعزول...';

  @override
  String get previewCleaning => 'جاري إنهاء بيئة العزل ومسح الذاكرة المؤقتة...';

  @override
  String get previewReady => 'اكتمل العرض المعزول بأمان';

  @override
  String get closePreview => 'إغلاق وتدمير بيئة العزل';

  @override
  String get testSandboxSecurity => 'إجراء اختبار التحقق الأمني للعزل';

  @override
  String get testResultsTitle => 'نتائج اختبارات العزل الأمني';

  @override
  String get testPassed => 'ناجح (تم حظر التهديد)';

  @override
  String get testFailed => 'فشل';

  @override
  String get networkBlockedTest => 'محاولة فتح اتصال بالشبكة';

  @override
  String get fsBlockedTest => 'محاولة قراءة ملف خارج القائمة البيضاء';

  @override
  String get dangerWarning =>
      'بيئة معزولة أمنيًا — يُحظر أي وصول غير مصرّح لنظام المضيف';

  @override
  String get fileDetails => 'تفاصيل الملف';

  @override
  String get fileName => 'اسم الملف';

  @override
  String get fileSize => 'حجم الملف';

  @override
  String get fileType => 'النوع';

  @override
  String sandboxInfoLabel(String mechanism) {
    return 'بيئة العزل: $mechanism';
  }

  @override
  String get selectImages => 'اختيار صور متعددة';

  @override
  String get selectVideos => 'اختيار مقاطع فيديو متعددة';

  @override
  String get multiImageViewer => 'معرض صور معزول';

  @override
  String get multiVideoPlaylist => 'قائمة تشغيل فيديو معزولة';

  @override
  String get previousImage => 'الصورة السابقة';

  @override
  String get nextImage => 'الصورة التالية';

  @override
  String get previousVideo => 'الفيديو السابق';

  @override
  String get nextVideo => 'الفيديو التالي';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get mute => 'كتم الصوت';

  @override
  String get unmute => 'إلغاء كتم الصوت';

  @override
  String get volume => 'مستوى الصوت';

  @override
  String get repeatMode => 'وضع التكرار';

  @override
  String get repeatOff => 'التكرار: معطّل';

  @override
  String get repeatOne => 'تكرار: الفيديو الحالي';

  @override
  String get repeatAll => 'تكرار: كل القائمة';

  @override
  String get playlist => 'قائمة التشغيل';

  @override
  String imagePosition(int current, int total) {
    return 'صورة $current من $total';
  }

  @override
  String videoPosition(int current, int total) {
    return 'فيديو $current من $total';
  }

  @override
  String get swipeHint =>
      'اسحب لليمين/اليسار أو استخدم أسهم لوحة المفاتيح للتنقل';

  @override
  String get developer => 'المطور';
}
