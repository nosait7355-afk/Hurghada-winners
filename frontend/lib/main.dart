import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/refresh/page_refresh.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.warmUp();

  await initializeDateFormatting('ar', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initDependencies();

  runApp(
    ProviderScope(
      observers: [dataProviderTracker],
      child: const BasketballAcademyApp(),
    ),
  );
}

class BasketballAcademyApp extends ConsumerWidget {
  const BasketballAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // الويب فقط: على نوافذ تابلت/ديسكتوب نستخدم designSize كبير (نفس فكرة
    // نسخة Windows: 1366x768) بدل 390x844 الخاص بالموبايل، حتى تبقى وحدات
    // ScreenUtil (.w/.h/.r/.sp) قريبة من 1:1 بدون أي تكبير أو Letterbox أو
    // Center(maxWidth) — العرض الكامل يُستخدم كما هو في نسخة Windows.
    // على Android تبقى designSize 390x844 كما كانت دائماً، بدون أي تغيير.
    Widget app = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWideWeb = kIsWeb && width >= kTabletBreakpoint;
        final designSize =
            isWideWeb ? const Size(1366, 768) : const Size(390, 844);

        return ScreenUtilInit(
          designSize: designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              title: 'Hurghada Winners',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              routerConfig: router,
              builder: (context, widget) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget ?? const SizedBox.shrink()),
                      // زر تحديث الصفحة الحالية — في كل الصفحات عدا شاشة البداية.
                      GlobalRefreshButton(
                        router: router,
                        hiddenOn: const {AppRoutes.splash},
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    return app;
  }
}
