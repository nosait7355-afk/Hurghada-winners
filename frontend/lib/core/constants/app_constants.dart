/// بيانات فرع من فروع الأكاديمية (اسم عربي + اسم إنجليزي).
/// كل فرع هو سجل أكاديمية (Academy) مستقل في الباك إند — academyId هو اللي
/// بيحدد الفرع اللي يتسجل فيه طلب انضمام اللاعب.
class BranchInfo {
  final String name;
  final String nameEn;
  final String academyId;

  const BranchInfo({
    required this.name,
    required this.nameEn,
    required this.academyId,
  });
}

class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://hurghada-winners.vercel.app/api/v1',
  );

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  // نوع الجلسة: 'admin' أو 'player' (منصة Nosait SaaS).
  static const String sessionTypeKey = 'session_type';

  // اسم المنصة (Hurghada Winners SaaS).
  static const String platformName = 'Hurghada Winners';

  // Timeouts (ms)
  // الاتصال يفشل أسرع (مع إعادة محاولة تلقائية واحدة في ApiClient) بدل تعليق
  // المستخدم 30 ثانية؛ الاستقبال يبقى أطول لرفع الصور/الفيديو.
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Player Code
  static const String playerCodePrefix = 'Y';

  // Evaluation range
  static const int minEvaluationScore = 1;
  static const int maxEvaluationScore = 10;

  // App Info
  static const String appName = 'Basketball Academy Manager';
  static const String appVersion = '1.2.2';
  static const int appBuild = 18;

  // Privacy Policy — official link opened in the device's default browser.
  // Change this value to update the link without touching any other code.
  static const String privacyPolicyUrl = 'https://winners.nosait.com/privacy.html';

  // معرّف خاص يُمرَّر مكان academyId في مسارات اللاعبين/الاشتراكات ليعني
  // "كل الفروع" — للسوبر أدمن فقط، والباك إند يتحقق من الدور.
  static const String allAcademiesId = 'all';

  // عنوان نسخة الويب — تُبنى عليه روابط مشاركة بروفايل اللاعب
  // (hash routing: https://winners.nosait.com/#/p/<token>).
  static const String publicWebBaseUrl = 'https://winners.nosait.com';

  // Company contact (WhatsApp) for "create account / inquiry".
  static const String companyWhatsappNumber = '+201062679402';

  // رقم الدفع (انستا باي / فودافون كاش) في رسائل تذكير تجديد الاشتراك.
  static const String renewalPaymentNumber = '01010555597';

  // الدعم الفني — رسائل واتساب على نفس الرقم، برسالة جاهزة مختلفة.
  static const String supportWhatsappNumber = companyWhatsappNumber;
  static const String supportDefaultMessage =
      'السلام عليكم\n'
      'محتاج مساعدة من الدعم الفني في تطبيق Hurghada Winners.\n\n'
      'المشكلة:\n'
      '....................';
  static const String contactDefaultMessage =
      'مرحباً\n\n'
      'أرغب في إنشاء حساب جديد أو الاستفسار عن نظام إدارة الأكاديميات الرياضية.\n\n'
      'الاسم:\n'
      '....................\n\n'
      'رقم الهاتف:\n'
      '....................';

  // رقم واتساب الأكاديمية — زر "تواصل معنا" في شاشة الترحيب.
  static const String academyWhatsappNumber = '+201111835595';

  // ── فروع الأكاديمية (تظهر في شاشة "الفروع" وفي طلب انضمام اللاعب) ──
  // academyId = سجل الأكاديمية في قاعدة tennis_academy — لا تغيّره مع الاسم.
  static const List<BranchInfo> branches = [
    BranchInfo(
      name: 'نادى الغردقة الرياضى',
      nameEn: 'Hurghada Sporting Club',
      academyId: '6aedd7db5ed894e2beec0a5b',
    ),
    BranchInfo(
      name: 'فندق سندباد',
      nameEn: 'Sindbad Hotel',
      academyId: '6aedd7db5ed894e2beec0a61',
    ),
    BranchInfo(
      name: 'فندق الكونتينتال',
      nameEn: 'Continental Hotel',
      academyId: '6aedd7db5ed894e2beec0a64',
    ),
    BranchInfo(
      name: 'مدرسة رجاك',
      nameEn: 'Rajac School',
      academyId: '6aedd7dc5ed894e2beec0a67',
    ),
  ];
}
