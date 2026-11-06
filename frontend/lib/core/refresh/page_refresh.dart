// زر "تحديث" عام يظهر في كل صفحات التطبيق والموقع ويعيد تحميل الصفحة الحالية.
//
// كيف يعمل التحديث:
//  1. DataProviderTracker (ProviderObserver) يتتبّع كل Provider حالته AsyncValue
//     (أي مزوّدات جلب البيانات: FutureProvider / AsyncNotifier / StateNotifier
//     الذي يحمل AsyncValue، وكل StateNotifierProvider.autoDispose الخاص بالشاشات)
//     — ثم نعمل لها invalidate فتُجلب البيانات من جديد.
//     مزوّدات الحالة البسيطة (الفلاتر، التبويب المختار…) لا تُلمس.
//  2. RefreshablePage يغلّف كل صفحة في الراوتر، ويعيد بناءها بمفتاح جديد حتى
//     تعيد الشاشات التي تجلب بياناتها في initState تحميلها أيضاً.
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// مزوّدات الجلسة لا نعيد تحميلها — إعادة بنائها تسبب وميض تسجيل الدخول/التحويل.
final Set<Object> _excluded = {authStateProvider, playerSessionProvider};

class DataProviderTracker extends ProviderObserver {
  final Map<ProviderBase<Object?>, ProviderContainer> _live = {};

  bool _isExcluded(ProviderBase<Object?> p) =>
      _excluded.contains(p) || (p.from != null && _excluded.contains(p.from));

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    // AsyncValue = مزوّد جلب بيانات. AutoDisposeStateNotifierProvider = حالة شاشة
    // (مثل قوائم المباريات) تجلب بياناتها عند الإنشاء — إعادة إنشائها = إعادة تحميل.
    final isData = value is AsyncValue || provider is AutoDisposeStateNotifierProvider;
    if (isData && !_isExcluded(provider)) _live[provider] = container;
  }

  @override
  void didDisposeProvider(ProviderBase<Object?> provider, ProviderContainer container) {
    _live.remove(provider);
  }

  void invalidateAll() {
    for (final e in _live.entries.toList()) {
      e.value.invalidate(e.key);
    }
  }
}

final dataProviderTracker = DataProviderTracker();

/// يزيد مع كل ضغطة تحديث؛ الصفحات تستمع له لتعيد بناء نفسها.
final ValueNotifier<int> pageRefreshEpoch = ValueNotifier<int>(0);

void refreshCurrentPage() {
  dataProviderTracker.invalidateAll();
  pageRefreshEpoch.value++;
}

class RefreshablePage extends StatelessWidget {
  final Widget child;
  const RefreshablePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageRefreshEpoch,
      builder: (_, epoch, __) => KeyedSubtree(key: ValueKey(epoch), child: child),
    );
  }
}

/// يغلّف كل GoRoute (وما تحته) بـ RefreshablePage.
List<RouteBase> refreshableRoutes(List<RouteBase> routes) {
  return routes.map((r) {
    if (r is GoRoute && r.builder != null && r.pageBuilder == null) {
      final b = r.builder!;
      return GoRoute(
        path: r.path,
        name: r.name,
        parentNavigatorKey: r.parentNavigatorKey,
        redirect: r.redirect,
        routes: refreshableRoutes(r.routes),
        builder: (context, state) => RefreshablePage(child: b(context, state)),
      );
    }
    return r;
  }).toList();
}

/// زر عائم صغير فوق كل الصفحات (يوضع في MaterialApp.builder داخل Stack).
class GlobalRefreshButton extends StatefulWidget {
  final GoRouter router;
  final Set<String> hiddenOn;
  const GlobalRefreshButton({super.key, required this.router, this.hiddenOn = const {}});

  @override
  State<GlobalRefreshButton> createState() => _GlobalRefreshButtonState();
}

class _GlobalRefreshButtonState extends State<GlobalRefreshButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_spin.isAnimating) return;
    refreshCurrentPage();
    _spin.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.router.routerDelegate,
      builder: (context, _) {
        final path = widget.router.routerDelegate.currentConfiguration.uri.path;
        final hidden = widget.hiddenOn.contains(path);
        final media = MediaQuery.of(context);
        final wide = media.size.width >= 700;
        // RTL: زر الـ FAB في الموبايل يكون يساراً، والقائمة الجانبية في الديسكتوب يميناً.
        return Positioned(
          right: wide ? null : 12,
          left: wide ? 24 : null,
          bottom: media.padding.bottom + (wide ? 24 : 88),
          child: hidden
              ? const SizedBox.shrink()
              : Semantics(
                  button: true,
                  label: 'تحديث الصفحة',
                  child: Material(
                    color: AppColors.surface,
                    elevation: 4,
                    shape: const CircleBorder(side: BorderSide(color: AppColors.grey200)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: RotationTransition(
                          turns: _spin,
                          child: const Icon(Icons.refresh_rounded, size: 24, color: AppColors.grey700),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
