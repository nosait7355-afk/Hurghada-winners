/// بيانات فرع من فروع الأكاديمية (اسم + وصف + رابط خرائط جوجل).
/// كل فرع هو سجل أكاديمية (Academy) مستقل بالكامل في الباك إند — لذلك لكل
/// فرع academyId خاص به يُستخدم عند إرسال طلب انضمام لاعب جديد لهذا الفرع.
class BranchInfo {
  final String name;
  final String description;
  final String mapsUrl;
  final String academyId;

  const BranchInfo({
    required this.name,
    required this.description,
    required this.mapsUrl,
    required this.academyId,
  });
}

class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://my-coach-backend.vercel.app/api/v1',
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
  static const String privacyPolicyUrl = 'https://nosait.com/privacy';

  // معرّف خاص يُمرَّر مكان academyId في مسارات اللاعبين/الاشتراكات ليعني
  // "كل الفروع" — للسوبر أدمن فقط، والباك إند يتحقق من الدور.
  static const String allAcademiesId = 'all';

  // عنوان نسخة الويب — تُبنى عليه روابط مشاركة بروفايل اللاعب
  // (hash routing: https://coach.nosait.com/#/p/<token>).
  static const String publicWebBaseUrl = 'https://coach.nosait.com';

  // Company contact (WhatsApp) for "create account / inquiry".
  static const String companyWhatsappNumber = '+201062679402';

  // رقم الدفع (انستا باي / فودافون كاش) في رسائل تذكير تجديد الاشتراك.
  static const String renewalPaymentNumber = '01010555597';

  // الدعم الفني — رسائل واتساب على نفس الرقم، برسالة جاهزة مختلفة.
  static const String supportWhatsappNumber = companyWhatsappNumber;
  static const String supportDefaultMessage =
      'السلام عليكم\n'
      'محتاج مساعدة من الدعم الفني في تطبيق ماي كوتش.\n\n'
      'المشكلة:\n'
      '....................';
  static const String contactDefaultMessage =
      'مرحباً\n\n'
      'أرغب في إنشاء حساب جديد أو الاستفسار عن نظام إدارة الأكاديميات الرياضية.\n\n'
      'الاسم:\n'
      '....................\n\n'
      'رقم الهاتف:\n'
      '....................';

  // ── فروع وملاعب الأكاديمية (تظهر في شاشة "الفروع") ──
  static const List<BranchInfo> branches = [
    BranchInfo(
      name: 'فرع مدينة الشروق',
      description:
          'ملعب الحريف 1 - الجراش - خلف بنك القاهرة - والمدرسة اليابانية',
      mapsUrl: 'https://maps.google.com/?q=30.157984,31.621401',
      academyId: '6a73d579c94b86f12268179a',
    ),
    // تحذير: academyId هو ما يحدّد الأكاديمية التي يُسجَّل فيها اللاعب فعلياً
    // — لا الاسم. عند تغيير أي اسم هنا لا تغيّر معه الـ academyId المرافق،
    // وإلا ذهب المسجَّلون إلى الفرع الخطأ.
    BranchInfo(
      name: 'فرع المخابرات',
      description: 'مدينة بدر - ملعب المخابرات',
      mapsUrl: 'https://maps.google.com/?q=Mokhabarat+Badr',
      academyId: '6a73d53dc94b86f12268178e',
    ),
    BranchInfo(
      name: 'فرع النرجس',
      description: 'مدينة بدر - ملعب النرجس',
      mapsUrl: 'https://maps.google.com/?q=Narges+Badr',
      academyId: '6a73d524c94b86f122681788',
    ),
    BranchInfo(
      name: 'فرع زهرة العاصمة',
      description: 'المجمع الرياضي',
      mapsUrl: 'https://maps.google.com/?q=Sports+Complex+Capital',
      academyId: '6a73d561c94b86f122681794',
    ),
  ];

  // ── نبذة عن الأكاديمية ──
  static const String aboutAcademyText =
      'Hurghada Winners Tennis academy\n'
      'اكاديمية Tennis لتأسيس وتطوير لاعبي Tennis للبراعم والناشئين\n\n'
      'بنقبل من اول ٣ سنين ( اولاد - بنات )\n\n'
      'مش بس اكاديمية تعليمية احنا كمان بنعتمد علي بناء وتطوير شخصية الولد '
      'ليكون قادر علي الاعتماد علي نفسه\n\n'
      'مرخصة من قبل الاتحاد المصري لكرة القدم ووزارة الشباب والرياضة\n\n'
      'مجموعة من المدربين المؤهلين والمتخصصين في مجال Tennis والحاصلين '
      'علي الشهادات والدورات التدريبية المعتمدة من الاتحاد المصري والاتحاد الافريقي\n\n'
      'كمان بنسوق اللعيبة في افضل واكبر الاندية زي ( الاهلي ، انبي ، المقاولين ، '
      'النصر وغيرها من الاندية )\n\n'
      'بنطور ابنك من جميع الجوانب البدنية والمهارية والخططية\n'
      'والتطور دا بيكون ملحوظ علي ابنك في خلال ٣ شهور باذن الله\n\n'
      'جوايز وهدايا ومكافات كتير\n'
      'واحتفالات وتكريمات للاولاد واولياء امورهم واعياد ميلادهم\n\n'
      'فروعنا في كل مكان حواليك\n'
      'تقدر تتواصل معانا وتحجز اول تمرينة مجانا';

  // عدد صور معرض "نبذة عن الأكاديمية" (assets/images/about/about_01.jpg ... about_22.jpg)
  static const int aboutGalleryImageCount = 22;
}
