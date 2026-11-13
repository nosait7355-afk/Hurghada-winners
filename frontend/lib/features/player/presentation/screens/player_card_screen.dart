import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/services/player_card_pdf_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// اسم مدير الأكاديمية الظاهر في تذييل كل بطاقة لاعب — ثابت لكل الأكاديميات
/// بحسب المتطلبات الحالية (لا يوجد بعد حقل مدير مرتبط بالأكاديمية في النظام).
const String _kAcademyDirector = 'دكتور / محمد خميس';

/// الاسم التجاري الثابت الظاهر في رأس كل بطاقة — لا يتغيّر بتغيّر الفرع.
const String _kAcademyBrand = 'أكاديمية Hurghada Winners';

/// بطاقة تعريف دائمة للاعب — تُطبع مرة واحدة. تحتوي: شعار واسم الأكاديمية،
/// الرياضة، صورة اللاعب، اسمه، الكود، المجموعة، ورمز QR.
///
/// التصدير إلى PDF يلتقط نفس Widget البطاقة المعروض على الشاشة كصورة PNG عالية
/// الدقة عبر RepaintBoundary ثم يضعها داخل صفحة PDF — فلا يوجد رسم ثانٍ للبطاقة
/// إطلاقاً، والنتيجة مطابقة 100% لما يظهر داخل التطبيق.
class PlayerCardScreen extends ConsumerStatefulWidget {
  final PlayerEntity player;
  const PlayerCardScreen({super.key, required this.player});

  @override
  ConsumerState<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends ConsumerState<PlayerCardScreen> {
  /// مفتاح الـ RepaintBoundary الذي يغلّف البطاقة المعروضة — هو مصدر الالتقاط.
  final GlobalKey _cardKey = GlobalKey();

  /// محتوى الـ QR — معرّف ثابت مشتق من كود اللاعب (لا يتغيّر مدى الحياة).
  String get _qrData => 'PLAYER:${widget.player.playerCode}';

  /// يلتقط Widget البطاقة المعروضة كصورة PNG عالية الدقة (≥ 300 DPI عند الطباعة)
  /// دون أي إعادة رسم — نفس الـ Gradient/Shadow/BorderRadius/الخطوط/الألوان.
  Future<Uint8List> _capturePng() async {
    // نلتقط مرجع الـ RenderObject قبل أي await (فلا نحمل BuildContext عبر فجوة
    // غير متزامنة) — الـ RenderObject يبقى صالحاً طوال عملية الالتقاط.
    final cardContext = _cardKey.currentContext;
    if (cardContext == null) {
      throw StateError('تعذّر التقاط البطاقة — لم تُرسم بعد');
    }
    final boundary = cardContext.findRenderObject() as RenderRepaintBoundary;

    // ننتظر نهاية الإطار الحالي لضمان اكتمال رسم البطاقة (الصورة/الشعار/QR).
    await WidgetsBinding.instance.endOfFrame;

    // نستهدف عرضاً بكسلياً ~3500px كي لا تقل الجودة عن 300 DPI عند طباعة
    // البطاقة على عرض صفحة A4 أفقية. PixelRatio يُشتق من الحجم المنطقي الفعلي.
    const targetWidth = 3500.0;
    final pixelRatio = (targetWidth / boundary.size.width).clamp(3.0, 10.0);

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('تعذّر تحويل البطاقة إلى صورة');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final academy = ref.watch(academyByIdProvider(player.academyId)).valueOrNull;
    // اسم الفرع الذي ينتمي إليه اللاعب — يظهر بجوار الاسم التجاري الثابت.
    final branchName = academy?.name ?? '';
    final academyLogoUrl = academy?.logoUrl;
    final birthDate = intl.DateFormat('dd / MM / yyyy').format(player.birthDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بطاقة اللاعب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          children: [
            Center(
              // RepaintBoundary يغلّف البطاقة نفسها المعروضة — نلتقطها كما هي.
              // Padding شفاف حولها كي يُلتقط الظل (Shadow) كاملاً دون قص.
              child: RepaintBoundary(
                key: _cardKey,
                child: Padding(
                  padding: EdgeInsets.all(28.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 560.w),
                    child: AspectRatio(
                      aspectRatio: 1.586,
                      child: _CardView(
                        branchName: branchName,
                        academyLogoUrl: academyLogoUrl,
                        fullName: player.fullName,
                        playerCode: player.playerCode,
                        sport: player.sport ?? '',
                        birthDate: birthDate,
                        imageUrl: player.imageUrl,
                        qrData: _qrData,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Gap(28.h),
            _ActionButtons(
              // نفس البطاقة الملتقطة هي مصدر الـ PDF والصورة معاً — لا رسم ثانٍ.
              buildPdf: () async {
                final png = await _capturePng();
                return PlayerCardPdfService.generateFromImage(png);
              },
              buildImage: _capturePng,
              fileName: 'player_card_${player.playerCode}.pdf',
              imageFileName: 'player_card_${player.playerCode}.png',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// بطاقة عضوية رياضية فاخرة — رأس بتدرّج أزرق مضغوط، وجسم أبيض موسّع (صورة
// كبيرة + اسم اللاعب + QR كبير) يمتد حتى الزوايا السفلية المستديرة.
// ---------------------------------------------------------------------------

class _CardView extends StatelessWidget {
  final String branchName;
  final String? academyLogoUrl;
  final String fullName;
  final String playerCode;
  final String sport;
  final String birthDate;
  final String? imageUrl;
  final String qrData;

  const _CardView({
    required this.branchName,
    required this.academyLogoUrl,
    required this.fullName,
    required this.playerCode,
    required this.sport,
    required this.birthDate,
    required this.imageUrl,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final radius = w * 0.045;
        // حجم QR — 21% من عرض البطاقة، في عمود مستقل تماماً عن عمود الصورة
        // والبيانات (لا تداخل ممكن بنيوياً).
        final qrSize = w * 0.21;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              // ظل أزرق ناعم — الهوية الأساسية للبطاقة
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.16),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              // ظل ثانوي صغير — يمنح البطاقة عمقاً واقعياً قريباً من السطح
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // خلفية هندسية خفيفة جداً — خطوط ملعب كرة قدم (دائرة المنتصف
                // + خط الوسط + قوس ركنية) بشفافية 2~3% فقط. لا تؤثر أبداً على
                // وضوح القراءة.
                Positioned.fill(
                  child: CustomPaint(painter: _PitchPatternPainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 17,
                      child: _Header(
                        w: w,
                        branchName: branchName,
                        academyLogoUrl: academyLogoUrl,
                        sport: sport,
                      ),
                    ),
                    // ── جسم البطاقة: QR (يسار) | فاصل | بيانات اللاعب | صورة
                    // (يمين) — كل عنصر في عموده الخاص فلا تداخل ممكن بنيوياً.
                    Expanded(
                      flex: 60,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _PlayerPhoto(w: w, imageUrl: imageUrl),
                              SizedBox(width: w * 0.03),
                              Expanded(
                                child: _InfoColumn(
                                  w: w,
                                  fullName: fullName,
                                  playerCode: playerCode,
                                  birthDate: birthDate,
                                  sport: sport,
                                ),
                              ),
                              SizedBox(width: w * 0.03),
                              Container(
                                width: 1.2,
                                height: double.infinity,
                                color: AppColors.secondary.withValues(alpha: 0.22),
                              ),
                              SizedBox(width: w * 0.03),
                              _QrColumn(w: w, qrSize: qrSize, qrData: qrData),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 23,
                      child: _DirectorFooter(w: w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// خطوط ملعب كرة قدم خفيفة جداً — زخرفة هوية رياضية دون أي تأثير على القراءة.
class _PitchPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // دائرة المنتصف — أعلى يسار البطاقة
    canvas.drawCircle(Offset(size.width * 0.14, size.height * 0.02), size.width * 0.12, paint);
    // خط منتصف الملعب
    canvas.drawLine(
      Offset(size.width * 0.26, -size.height * 0.1),
      Offset(size.width * 0.26, size.height * 0.5),
      paint,
    );
    // قوس ركنية — أسفل يمين البطاقة
    final cornerRect = Rect.fromCircle(
      center: Offset(size.width * 1.0, size.height * 1.02),
      radius: size.width * 0.16,
    );
    canvas.drawArc(cornerRect, 3.14, 1.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── رأس البطاقة: شعار (يسار) + اسم الأكاديمية الثابت | الفرع (وسط) + شارة ──
// ─── + تسمية "بطاقة لاعب رسمية" أسفل الرأس. رأس مضغوط بلا فراغ زائد. ────────
class _Header extends StatelessWidget {
  final double w;
  final String branchName;
  final String? academyLogoUrl;
  final String sport;

  const _Header({
    required this.w,
    required this.branchName,
    required this.academyLogoUrl,
    required this.sport,
  });

  @override
  Widget build(BuildContext context) {
    // يتناسب مع عرض البطاقة مع إبقاء مساحة كافية لتسمية «بطاقة لاعب رسمية»
    // داخل ارتفاع الرأس الثابت (17%) — بدون أي تجاوز (overflow).
    final logoSize = w * 0.058;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.006),
      // اتجاه ثابت LTR لضمان بقاء الشعار يساراً والشارة يميناً فعلياً — نصوص
      // العربية تُشكَّل بصرياً بشكل صحيح تلقائياً بصرف النظر عن اتجاه الحاوية.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT — شعار الأكاديمية
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: AppColors.white, width: 1.4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 5, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipOval(
                    child: (academyLogoUrl != null && academyLogoUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: academyLogoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _logoPlaceholder(logoSize),
                            placeholder: (_, __) => _logoPlaceholder(logoSize),
                          )
                        : _logoPlaceholder(logoSize),
                  ),
                ),
                SizedBox(width: w * 0.022),
                // CENTER — الاسم التجاري الثابت + اسم فرع اللاعب بجواره، سطر
                // واحد دائماً (FittedBox يصغّر بدل أن يكسر السطر أو يقصّه).
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _kAcademyBrand,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: w * 0.030,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              height: 1.1,
                            ),
                          ),
                          if (branchName.isNotEmpty) ...[
                            SizedBox(width: w * 0.014),
                            Container(
                              width: 1.2,
                              height: w * 0.030,
                              color: AppColors.white.withValues(alpha: 0.5),
                            ),
                            SizedBox(width: w * 0.014),
                            Text(
                              branchName,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: w * 0.024,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white.withValues(alpha: 0.95),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.018),
                // RIGHT — شارة الرياضة
                if (sport.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.007),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(w * 0.05),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.55), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_soccer, size: w * 0.017, color: AppColors.white),
                        SizedBox(width: w * 0.008),
                        Text(
                          sport,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: w * 0.017,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // BOTTOM — تسمية مصغّرة "بطاقة لاعب رسمية" (تتقلّص بدل أن تتجاوز)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.005),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(w * 0.04),
                  ),
                  child: Text(
                    'بطاقة لاعب رسمية',
                    style: TextStyle(
                      fontSize: w * 0.014,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white.withValues(alpha: 0.92),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _logoPlaceholder(double size) => Container(
        color: AppColors.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(Icons.shield_outlined, size: size * 0.55, color: AppColors.secondary),
      );
}

// ─── صورة اللاعب الدائرية — أقصى يمين جسم البطاقة، يسبق عمود البيانات. ─────
class _PlayerPhoto extends StatelessWidget {
  final double w;
  final String? imageUrl;

  const _PlayerPhoto({required this.w, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final photoSize = w * 0.24;
    return Container(
      width: photoSize,
      height: photoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 3.4),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _avatarPlaceholder(photoSize),
                placeholder: (_, __) => _avatarPlaceholder(photoSize),
              )
            : _avatarPlaceholder(photoSize),
      ),
    );
  }

  static Widget _avatarPlaceholder(double size) => Container(
        color: AppColors.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: size * 0.55, color: AppColors.secondary),
      );
}

// ─── عمود بيانات اللاعب: اسم بارز + شارة الكود + صفوف بيانات (كود/تاريخ
// ميلاد/رياضة) بأيقونات صغيرة — مطابق لتوزيع البطاقة المرجعية. ─────────────
class _InfoColumn extends StatelessWidget {
  final double w;
  final String fullName;
  final String playerCode;
  final String birthDate;
  final String sport;

  const _InfoColumn({
    required this.w,
    required this.fullName,
    required this.playerCode,
    required this.birthDate,
    required this.sport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // الاسم يتقلّص عند الطول بدل أن يُقصّ بثلاث نقاط — يبقى كاملاً دائماً.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            fullName,
            textAlign: TextAlign.right,
            maxLines: 1,
            style: TextStyle(
              fontSize: w * 0.044,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(height: w * 0.018),
        Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.011),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.secondaryLight, AppColors.secondary]),
            borderRadius: BorderRadius.circular(w * 0.05),
            boxShadow: [
              BoxShadow(color: AppColors.secondary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: w * 0.016, color: AppColors.white),
              SizedBox(width: w * 0.01),
              Text(
                playerCode,
                style: TextStyle(
                  fontSize: w * 0.024,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(width: w * 0.01),
              Icon(Icons.star, size: w * 0.016, color: AppColors.white),
            ],
          ),
        ),
        SizedBox(height: w * 0.022),
        _DataRow(w: w, icon: Icons.badge_outlined, label: 'كود اللاعب', value: playerCode),
        SizedBox(height: w * 0.012),
        _DataRow(w: w, icon: Icons.calendar_today_outlined, label: 'تاريخ الميلاد', value: birthDate),
        if (sport.isNotEmpty) ...[
          SizedBox(height: w * 0.012),
          _DataRow(w: w, icon: Icons.sports_soccer, label: 'الرياضة', value: sport),
        ],
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final double w;
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({required this.w, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: w * 0.02, color: AppColors.secondary),
        SizedBox(width: w * 0.01),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(fontSize: w * 0.017, fontWeight: FontWeight.w600, color: AppColors.secondaryLight),
        ),
        SizedBox(width: w * 0.012),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: w * 0.019, fontWeight: FontWeight.w800, color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

// ─── عمود الـQR: رمز كبير + عبارة المسح تحته. ───────────────────────────────
class _QrColumn extends StatelessWidget {
  final double w;
  final double qrSize;
  final String qrData;

  const _QrColumn({required this.w, required this.qrSize, required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: qrSize,
          height: qrSize,
          padding: EdgeInsets.all(w * 0.014),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(w * 0.028),
            border: Border.all(color: AppColors.secondary, width: 2.2),
            boxShadow: [
              BoxShadow(color: AppColors.secondary.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            backgroundColor: AppColors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.secondaryDark,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.secondaryDark,
            ),
            errorStateBuilder: (_, __) => Center(
              child: Text(
                'تعذّر توليد QR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.016, color: AppColors.secondaryDark),
              ),
            ),
          ),
        ),
        SizedBox(height: w * 0.01),
        Text(
          'امسح للحضور',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.015,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }
}

// ─── تذييل مدير الأكاديمية — قسم منفصل بصرياً أسفل البطاقة: بيانات المدير
// يميناً (التسمية + الاسم) دون أي تاريخ إصدار. ──────────────────────────────
class _DirectorFooter extends StatelessWidget {
  final double w;

  const _DirectorFooter({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryContainer.withValues(alpha: 0.55), AppColors.secondaryContainer.withValues(alpha: 0.9)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        border: const Border(top: BorderSide(color: AppColors.secondaryContainer, width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // يمين — اسم المدير
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مدير الأكاديمية',
                    style: TextStyle(fontSize: w * 0.015, fontWeight: FontWeight.w600, color: AppColors.secondaryLight),
                  ),
                  Text(
                    _kAcademyDirector,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: w * 0.02, fontWeight: FontWeight.w800, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// أزرار: تحميل PDF / مشاركة / طباعة
// ---------------------------------------------------------------------------

class _ActionButtons extends StatefulWidget {
  final Future<Uint8List> Function() buildPdf;
  final Future<Uint8List> Function() buildImage;
  final String fileName;
  final String imageFileName;
  const _ActionButtons({
    required this.buildPdf,
    required this.buildImage,
    required this.fileName,
    required this.imageFileName,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _busy = false;

  Future<void> _run(
    Future<Uint8List> Function() buildBytes,
    Future<void> Function(Uint8List bytes) action,
    String emptyErrorMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await buildBytes();
      if (bytes.isEmpty) {
        throw StateError(emptyErrorMessage);
      }
      await action(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر إنشاء البطاقة: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runPdf(Future<void> Function(Uint8List bytes) action) =>
      _run(widget.buildPdf, action, 'ملف PDF فارغ');

  Future<void> _downloadImage() => _run(
        widget.buildImage,
        (bytes) => Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: widget.imageFileName)],
          text: 'بطاقة اللاعب',
        ),
        'تعذّر توليد الصورة',
      );

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _runPdf((bytes) =>
                    Printing.sharePdf(bytes: bytes, filename: widget.fileName)),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('تحميل PDF'),
              ),
            ),
            Gap(8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('تحميل صورة عالية الدقة'),
              ),
            ),
          ],
        ),
        Gap(8.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () =>
                _runPdf((bytes) => Printing.layoutPdf(onLayout: (_) async => bytes)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة البطاقة'),
          ),
        ),
      ],
    );
  }
}
