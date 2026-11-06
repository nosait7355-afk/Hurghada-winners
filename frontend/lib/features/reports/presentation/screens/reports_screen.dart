import 'dart:typed_data';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/layout/desktop_grid.dart';
import 'package:hurghada_winners/core/layout/desktop_scaffold.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/currency_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/groups/presentation/providers/groups_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hurghada_winners/features/reports/domain/models/report_filter.dart';
import 'package:hurghada_winners/features/reports/services/excel_report_service.dart';
import 'package:hurghada_winners/features/reports/services/pdf_report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// Period enum
// ---------------------------------------------------------------------------

enum _ReportPeriod { thisMonth, last3Months, thisYear, allTime }

extension _ReportPeriodExt on _ReportPeriod {
  String get label {
    switch (this) {
      case _ReportPeriod.thisMonth:
        return AppStrings.thisMonth;
      case _ReportPeriod.last3Months:
        return AppStrings.last3Months;
      case _ReportPeriod.thisYear:
        return AppStrings.thisYear;
      case _ReportPeriod.allTime:
        return AppStrings.allTime;
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case _ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case _ReportPeriod.last3Months:
        return DateTime(now.year, now.month - 3, 1);
      case _ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case _ReportPeriod.allTime:
        return null;
    }
  }

  DateTime? get endDate {
    if (this == _ReportPeriod.allTime) return null;
    return DateTime.now();
  }
}

// ---------------------------------------------------------------------------
// Reports Screen
// ---------------------------------------------------------------------------

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportPeriod _period = _ReportPeriod.allTime;
  String? _selectedAcademyId;
  String? _selectedAcademyName;
  String? _selectedSport; // null = all sports
  String? _selectedGroupId; // null = all groups (independent of sport)
  String? _selectedGroupName;
  String _subscriptionStatusFilter = 'all'; // 'all' | 'active' | 'expired'

  // Loading states per report index (PDF)
  final List<bool> _loading = [false, false, false, false];
  // Loading states per report index (Excel)
  final List<bool> _loadingExcel = [false, false, false, false];

  ReportFilter get _currentFilter {
    return ReportFilter(
      academyId: _selectedAcademyId,
      academyName: _selectedAcademyName,
      startDate: _period.startDate,
      endDate: _period.endDate,
      subscriptionStatus:
          _subscriptionStatusFilter == 'all' ? null : _subscriptionStatusFilter,
      currencyLabel:
          ref.read(academyCurrencyLabelProvider(_selectedAcademyId)),
      sport: _selectedSport,
      groupId: _selectedGroupId,
      groupName: _selectedGroupName,
      isMultiSport: _selectedAcademyId == null
          ? false
          : (ref
                  .read(academyByIdProvider(_selectedAcademyId!))
                  .valueOrNull
                  ?.isMultiSport ??
              false),
    );
  }

  Future<void> _generateReport(int index) async {
    if (_selectedAcademyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الأكاديمية أولاً'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading[index] = true);

    try {
      Uint8List bytes;
      String fileName;

      switch (index) {
        case 0:
          bytes = await PdfReportService.generatePlayersReport(_currentFilter);
          fileName = 'players_report.pdf';
          break;
        case 1:
          bytes = await PdfReportService.generateSubscriptionsReport(
              _currentFilter);
          fileName = 'subscriptions_report.pdf';
          break;
        case 2:
          bytes =
              await PdfReportService.generateRevenueReport(_currentFilter);
          fileName = 'revenue_report.pdf';
          break;
        case 3:
          bytes = await PdfReportService.generateEvaluationsReport(
              _currentFilter);
          fileName = 'evaluations_report.pdf';
          break;
        default:
          return;
      }

      if (!mounted) return;

      _showReportBottomSheet(bytes, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.reportError}: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading[index] = false);
    }
  }

  void _showReportBottomSheet(Uint8List bytes, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'خيارات التقرير',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Gap(8.h),
            ListTile(
              leading: const Icon(Icons.preview_outlined,
                  color: AppColors.secondary),
              title: const Text(AppStrings.previewReport),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(
                    onLayout: (_) async => bytes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.primary),
              title: const Text(AppStrings.shareReport),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(
                    bytes: bytes, filename: fileName);
              },
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _generateExcel(int index) async {
    if (_selectedAcademyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الأكاديمية أولاً'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loadingExcel[index] = true);

    try {
      Uint8List bytes;
      String fileName;

      switch (index) {
        case 0:
          bytes = await ExcelReportService.generatePlayersExcel(_currentFilter);
          fileName = 'players_report.xlsx';
          break;
        case 1:
          bytes = await ExcelReportService.generateSubscriptionsExcel(_currentFilter);
          fileName = 'subscriptions_report.xlsx';
          break;
        case 2:
          bytes = await ExcelReportService.generateRevenueExcel(_currentFilter);
          fileName = 'revenue_report.xlsx';
          break;
        case 3:
          bytes = await ExcelReportService.generateEvaluationsExcel(_currentFilter);
          fileName = 'evaluations_report.xlsx';
          break;
        default:
          return;
      }

      if (!mounted) return;
      await ExcelReportService.shareExcel(bytes, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.reportError}: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingExcel[index] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final userAcademyId = user?.academyId;

    // admin لا يملك صلاحية التقارير
    if (user?.isAdmin == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (userAcademyId != null) {
          context.go(AppRoutes.playersList.replaceFirst(':id', userAcademyId));
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // For non-superadmin, use their academy id and resolve name
    if (!isSuperAdmin && _selectedAcademyId == null && userAcademyId != null) {
      final academiesAsync = ref.watch(academiesProvider);
      final academyName = academiesAsync.valueOrNull
          ?.firstWhere((a) => a.id == userAcademyId,
              orElse: () => academiesAsync.valueOrNull!.first)
          .name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedAcademyId = userAcademyId;
            _selectedAcademyName = academyName;
          });
        }
      });
    }

    // Resolve the selected academy's sports for the (optional) sport filter.
    final academyForSport = _selectedAcademyId != null
        ? ref.watch(academyByIdProvider(_selectedAcademyId!)).valueOrNull
        : null;
    final sportsForFilter = academyForSport?.sports ?? const <String>[];

    final tier =
        kIsWeb ? screenTierOf(MediaQuery.sizeOf(context).width) : ScreenTier.mobile;

    final reportDefs = [
      (
        index: 0,
        icon: Icons.people_alt_outlined,
        iconColor: AppColors.secondary,
        title: AppStrings.playersReport,
        description:
            'قائمة اللاعبين المسجلين مع حالة اشتراكاتهم ومعلومات أولياء الأمور',
        loading: _loading[0],
        loadingExcel: _loadingExcel[0],
        onGenerate: () => _generateReport(0),
        onExport: () => _generateExcel(0),
      ),
      (
        index: 1,
        icon: Icons.card_membership_outlined,
        iconColor: AppColors.primary,
        title: AppStrings.subscriptionsReport,
        description: 'سجل الاشتراكات والتجديدات مع تفاصيل المبالغ والتواريخ',
        loading: _loading[1],
        loadingExcel: _loadingExcel[1],
        onGenerate: () => _generateReport(1),
        onExport: () => _generateExcel(1),
      ),
      (
        index: 2,
        icon: Icons.payments_outlined,
        iconColor: AppColors.success,
        title: AppStrings.revenueReport,
        description: 'ملخص الإيرادات الكلية والشهرية وإحصائيات الاشتراكات',
        loading: _loading[2],
        loadingExcel: _loadingExcel[2],
        onGenerate: () => _generateReport(2),
        onExport: () => _generateExcel(2),
      ),
      (
        index: 3,
        icon: Icons.assessment_outlined,
        iconColor: Colors.deepPurple,
        title: AppStrings.evaluationsReport,
        description: 'سجل تقييمات اللاعبين بجميع المعايير والتقديرات',
        loading: _loading[3],
        loadingExcel: _loadingExcel[3],
        onGenerate: () => _generateReport(3),
        onExport: () => _generateExcel(3),
      ),
    ];

    if (tier != ScreenTier.mobile) {
      return DesktopScaffold(
        location: AppRoutes.reports,
        tier: tier,
        title: AppStrings.reports,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DesktopFilterBar(
              isSuperAdmin: isSuperAdmin,
              selectedAcademyId: _selectedAcademyId,
              sportsForFilter: sportsForFilter,
              selectedSport: _selectedSport,
              period: _period,
              subscriptionStatusFilter: _subscriptionStatusFilter,
              onAcademyChanged: (id, name) => setState(() {
                _selectedAcademyId = id;
                _selectedAcademyName = name;
                _selectedSport = null;
                _selectedGroupId = null;
                _selectedGroupName = null;
              }),
              onSportChanged: (s) => setState(() => _selectedSport = s),
              onPeriodChanged: (p) => setState(() => _period = p),
              onStatusChanged: (s) =>
                  setState(() => _subscriptionStatusFilter = s),
            ),
            const SizedBox(height: 20),
            DesktopGrid(
              isDesktop: tier == ScreenTier.desktop,
              childAspectRatio: 1.3,
              children: reportDefs
                  .map((r) => _DesktopReportCard(
                        icon: r.icon,
                        iconColor: r.iconColor,
                        title: r.title,
                        description: r.description,
                        loading: r.loading,
                        loadingExcel: r.loadingExcel,
                        onGenerate: r.onGenerate,
                        onExport: r.onExport,
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ----------------------------------------------------------------
          // Filter bar
          // ----------------------------------------------------------------
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Super admin: academy selector
                if (isSuperAdmin) ...[
                  _AcademyDropdown(
                    selectedAcademyId: _selectedAcademyId,
                    onChanged: (id, name) => setState(() {
                      _selectedAcademyId = id;
                      _selectedAcademyName = name;
                      _selectedSport = null; // reset sport on academy change
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                    }),
                  ),
                  Gap(12.h),
                ],
                // Sport filter — only for multi-sport academies
                if (sportsForFilter.length > 1) ...[
                  Text(
                    'الرياضة',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Gap(8.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: _StatusChip(
                            label: 'الكل',
                            selected: _selectedSport == null,
                            onTap: () => setState(() => _selectedSport = null),
                          ),
                        ),
                        ...sportsForFilter.map(
                          (s) => Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _StatusChip(
                              label: s,
                              selected: _selectedSport == s,
                              onTap: () => setState(() => _selectedSport = s),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(12.h),
                ],
                // Group filter — بُعد فلترة مستقل عن الرياضة (كل مجموعات الأكاديمية).
                if (_selectedAcademyId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final groupsAsync = ref.watch(groupsByAcademyProvider(
                        (academyId: _selectedAcademyId!, sportId: null),
                      ));
                      return groupsAsync.maybeWhen(
                        data: (groups) {
                          if (groups.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المجموعة',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppColors.grey600,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Gap(8.h),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: _StatusChip(
                                        label: 'الكل',
                                        selected: _selectedGroupId == null,
                                        onTap: () => setState(() {
                                          _selectedGroupId = null;
                                          _selectedGroupName = null;
                                        }),
                                      ),
                                    ),
                                    ...groups.map(
                                      (g) => Padding(
                                        padding: EdgeInsets.only(left: 8.w),
                                        child: _StatusChip(
                                          label: g.name,
                                          selected: _selectedGroupId == g.id,
                                          onTap: () => setState(() {
                                            _selectedGroupId = g.id;
                                            _selectedGroupName = g.name;
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Gap(12.h),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                // Period filter
                Text(
                  AppStrings.reportPeriod,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Gap(8.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _ReportPeriod.values
                        .map(
                          (p) => Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _PeriodChip(
                              label: p.label,
                              selected: _period == p,
                              onTap: () => setState(() => _period = p),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Gap(12.h),
                // Subscription status filter
                Text(
                  'حالة الاشتراك',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Gap(8.h),
                Row(
                  children: [
                    _StatusChip(
                      label: AppStrings.allSubscriptions,
                      selected: _subscriptionStatusFilter == 'all',
                      onTap: () =>
                          setState(() => _subscriptionStatusFilter = 'all'),
                    ),
                    Gap(8.w),
                    _StatusChip(
                      label: 'نشط',
                      selected: _subscriptionStatusFilter == 'active',
                      onTap: () =>
                          setState(() => _subscriptionStatusFilter = 'active'),
                      color: AppColors.success,
                    ),
                    Gap(8.w),
                    _StatusChip(
                      label: 'منتهي',
                      selected: _subscriptionStatusFilter == 'expired',
                      onTap: () =>
                          setState(() => _subscriptionStatusFilter = 'expired'),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ----------------------------------------------------------------
          // Report cards
          // ----------------------------------------------------------------
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _ReportCard(
                  index: 0,
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.secondary,
                  title: AppStrings.playersReport,
                  description:
                      'قائمة اللاعبين المسجلين مع حالة اشتراكاتهم ومعلومات أولياء الأمور',
                  loading: _loading[0],
                  loadingExcel: _loadingExcel[0],
                  onGenerate: () => _generateReport(0),
                  onExport: () => _generateExcel(0),
                ),
                Gap(12.h),
                _ReportCard(
                  index: 1,
                  icon: Icons.card_membership_outlined,
                  iconColor: AppColors.primary,
                  title: AppStrings.subscriptionsReport,
                  description:
                      'سجل الاشتراكات والتجديدات مع تفاصيل المبالغ والتواريخ',
                  loading: _loading[1],
                  loadingExcel: _loadingExcel[1],
                  onGenerate: () => _generateReport(1),
                  onExport: () => _generateExcel(1),
                ),
                Gap(12.h),
                _ReportCard(
                  index: 2,
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.success,
                  title: AppStrings.revenueReport,
                  description:
                      'ملخص الإيرادات الكلية والشهرية وإحصائيات الاشتراكات',
                  loading: _loading[2],
                  loadingExcel: _loadingExcel[2],
                  onGenerate: () => _generateReport(2),
                  onExport: () => _generateExcel(2),
                ),
                Gap(12.h),
                _ReportCard(
                  index: 3,
                  icon: Icons.assessment_outlined,
                  iconColor: Colors.deepPurple,
                  title: AppStrings.evaluationsReport,
                  description:
                      'سجل تقييمات اللاعبين بجميع المعايير والتقديرات',
                  loading: _loading[3],
                  loadingExcel: _loadingExcel[3],
                  onGenerate: () => _generateReport(3),
                  onExport: () => _generateExcel(3),
                ),
                Gap(24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Academy dropdown (super admin only)
// ---------------------------------------------------------------------------

class _AcademyDropdown extends ConsumerWidget {
  final String? selectedAcademyId;
  final void Function(String? id, String? name) onChanged;

  const _AcademyDropdown({
    required this.selectedAcademyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academiesAsync = ref.watch(academiesProvider);

    return academiesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (academies) => DropdownButtonFormField<String>(
        initialValue: selectedAcademyId,
        decoration: InputDecoration(
          labelText: 'اختر الأكاديمية',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          isDense: true,
        ),
        hint: const Text('اختر الأكاديمية'),
        items: academies
            .map(
              (a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name),
              ),
            )
            .toList(),
        onChanged: (id) {
          final name = academies.firstWhere((a) => a.id == id).name;
          onChanged(id, name);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period chip
// ---------------------------------------------------------------------------

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? activeColor : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report card
// ---------------------------------------------------------------------------

class _ReportCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool loading;
  final bool loadingExcel;
  final VoidCallback onGenerate;
  final VoidCallback onExport;

  const _ReportCard({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.loading,
    required this.loadingExcel,
    required this.onGenerate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon box
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 26.sp),
            ),
            Gap(14.w),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Gap(8.w),
            // Buttons column
            Column(
              children: [
                // PDF button
                SizedBox(
                  width: 82.w,
                  child: ElevatedButton(
                    onPressed: loading ? null : onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 9.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: loading
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppStrings.generatePdf,
                            style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                Gap(6.h),
                // Excel button
                SizedBox(
                  width: 82.w,
                  child: ElevatedButton(
                    onPressed: loadingExcel ? null : onExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217346), // Excel green
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 9.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: loadingExcel
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppStrings.generateExcel,
                            style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop/Tablet filter bar — same chips/dropdown, horizontal full-width
// layout instead of the mobile vertical stack.
// ---------------------------------------------------------------------------

class _DesktopFilterBar extends StatelessWidget {
  final bool isSuperAdmin;
  final String? selectedAcademyId;
  final List<String> sportsForFilter;
  final String? selectedSport;
  final _ReportPeriod period;
  final String subscriptionStatusFilter;
  final void Function(String? id, String? name) onAcademyChanged;
  final void Function(String?) onSportChanged;
  final void Function(_ReportPeriod) onPeriodChanged;
  final void Function(String) onStatusChanged;

  const _DesktopFilterBar({
    required this.isSuperAdmin,
    required this.selectedAcademyId,
    required this.sportsForFilter,
    required this.selectedSport,
    required this.period,
    required this.subscriptionStatusFilter,
    required this.onAcademyChanged,
    required this.onSportChanged,
    required this.onPeriodChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (isSuperAdmin)
            SizedBox(
              width: 240,
              child: _AcademyDropdown(
                selectedAcademyId: selectedAcademyId,
                onChanged: onAcademyChanged,
              ),
            ),
          if (sportsForFilter.length > 1)
            Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'الكل',
                  selected: selectedSport == null,
                  onTap: () => onSportChanged(null),
                ),
                ...sportsForFilter.map((s) => _StatusChip(
                      label: s,
                      selected: selectedSport == s,
                      onTap: () => onSportChanged(s),
                    )),
              ],
            ),
          Wrap(
            spacing: 8,
            children: _ReportPeriod.values
                .map((p) => _PeriodChip(
                      label: p.label,
                      selected: period == p,
                      onTap: () => onPeriodChanged(p),
                    ))
                .toList(),
          ),
          Wrap(
            spacing: 8,
            children: [
              _StatusChip(
                label: AppStrings.allSubscriptions,
                selected: subscriptionStatusFilter == 'all',
                onTap: () => onStatusChanged('all'),
              ),
              _StatusChip(
                label: 'نشط',
                selected: subscriptionStatusFilter == 'active',
                onTap: () => onStatusChanged('active'),
                color: AppColors.success,
              ),
              _StatusChip(
                label: 'منتهي',
                selected: subscriptionStatusFilter == 'expired',
                onTap: () => onStatusChanged('expired'),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop/Tablet report card — vertical layout, smaller than the mobile row
// card, fits inside DesktopGrid.
// ---------------------------------------------------------------------------

class _DesktopReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool loading;
  final bool loadingExcel;
  final VoidCallback onGenerate;
  final VoidCallback onExport;

  const _DesktopReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.loading,
    required this.loadingExcel,
    required this.onGenerate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 11, color: AppColors.grey500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: loading ? null : onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : const Text(AppStrings.generatePdf,
                          style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: loadingExcel ? null : onExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217346),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loadingExcel
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : const Text(AppStrings.generateExcel,
                          style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
