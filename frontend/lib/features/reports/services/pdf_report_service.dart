import 'dart:typed_data';

import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluations_by_academy_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/reports/domain/models/report_filter.dart';
import 'package:hurghada_winners/features/reports/services/report_sport_filter.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportService {
  PdfReportService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    _regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  // ---------------------------------------------------------------------------
  // Text helpers
  // ---------------------------------------------------------------------------

  static pw.Widget _text(
    String text, {
    bool bold = false,
    double size = 10,
    PdfColor? color,
  }) {
    return pw.Text(
      text,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
        font: bold ? _bold : _regular,
        fontSize: size,
        color: color,
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: _text(
        text,
        bold: bold || isHeader,
        size: isHeader ? 9 : 8.5,
        color: isHeader ? PdfColors.white : PdfColors.black,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page header
  // ---------------------------------------------------------------------------

  static pw.Widget _buildHeader(
      String title, String academyName, String dateRange) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E85D04'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _text(title, bold: true, size: 16, color: PdfColors.white),
              if (academyName.isNotEmpty)
                _text(academyName, size: 10, color: PdfColors.white),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (academyName.isNotEmpty)
                _text(academyName, bold: true, size: 12, color: PdfColors.white),
              _text(dateRange, size: 9, color: PdfColors.white),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table styling
  // ---------------------------------------------------------------------------

  static pw.TableBorder get _tableBorder =>
      pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 0.5);
  static PdfColor get _headerColor => PdfColor.fromHex('#1A2B4A');
  static PdfColor get _altRowColor => PdfColor.fromHex('#F9FAFB');

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  static String _dateRange(ReportFilter filter) {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    if (filter.startDate == null && filter.endDate == null) {
      return 'كل الوقت';
    }
    final start =
        filter.startDate != null ? fmt.format(filter.startDate!) : '...';
    final end = filter.endDate != null ? fmt.format(filter.endDate!) : '...';
    return '$start - $end';
  }

  static String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'ar').format(d);

  // ---------------------------------------------------------------------------
  // 1. Players Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generatePlayersReport(ReportFilter filter) async {
    await _loadFonts();

    final playersUC = sl<GetPlayersUsecase>();
    final subsUC = sl<GetSubscriptionsByAcademyUsecase>();

    final academyId = filter.academyId;

    final playersResult = await playersUC(
      GetPlayersParams(
          academyId: academyId,
          sport: filter.sport,
          groupId: filter.groupId,
          page: 1,
          limit: 500),
    );

    final players = playersResult.fold((_) => [], (r) => r.players);

    // Fetch subscriptions to determine status per player
    Map<String, String> playerStatusMap = {};
    if (academyId != null) {
      final subsResult = await subsUC(
        GetSubscriptionsByAcademyParams(
            academyId: academyId, page: 1, limit: 500),
      );
      subsResult.fold((_) => null, (r) {
        for (final sub in r.subscriptions) {
          // Keep the most recent active sub if exists
          if (sub.isActive) {
            playerStatusMap[sub.playerId] = 'نشط';
          } else {
            playerStatusMap.putIfAbsent(sub.playerId, () => 'منتهي');
          }
        }
      });
    }

    final pdf = pw.Document();

    // Header row
    final headers = [
      'حالة الاشتراك',
      'رقم الهاتف',
      'المهنة',
      'اسم ولي الأمر',
      'تاريخ الميلاد',
      'الاسم',
      'الكود',
    ];

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.4),
      1: const pw.FlexColumnWidth(1.6),
      2: const pw.FlexColumnWidth(1.3),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(1.4),
      5: const pw.FlexColumnWidth(2.0),
      6: const pw.FlexColumnWidth(1.0),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير اللاعبين${filter.scopeSuffix}', filter.academyName ?? '', _dateRange(filter)),
          pw.SizedBox(height: 16),
          _text('إجمالي اللاعبين: ${players.length}',
              bold: true, size: 11, color: PdfColor.fromHex('#1A2B4A')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children:
                    headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              // Data
              if (players.isEmpty)
                pw.TableRow(
                  children: List.generate(
                    headers.length,
                    (i) => i == 3 ? _cell('لا توجد بيانات') : _cell(''),
                  ),
                )
              else
                ...players.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final rowColor =
                      idx.isOdd ? _altRowColor : PdfColors.white;
                  final status =
                      playerStatusMap[p.id] ?? 'جديد';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _cell(status),
                      _cell(p.parentPhone),
                      _cell(p.parentJob ?? '-'),
                      _cell(p.parentName),
                      _cell(_fmtDate(p.birthDate)),
                      _cell(p.fullName, bold: true),
                      _cell(p.playerCode),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 2. Subscriptions Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generateSubscriptionsReport(
      ReportFilter filter) async {
    await _loadFonts();

    final academyId = filter.academyId ?? '';
    final subsUC = sl<GetSubscriptionsByAcademyUsecase>();

    final subsResult = await subsUC(
      GetSubscriptionsByAcademyParams(
        academyId: academyId,
        status: filter.subscriptionStatus,
        page: 1,
        limit: 500,
      ),
    );

    var subs = subsResult.fold((_) => [], (r) => r.subscriptions);
    // Scope to a single sport by player id (single extra query, filtered locally)
    final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
    if (sportIds != null) {
      subs = subs.where((s) => sportIds.contains(s.playerId)).toList();
    }
    final total =
        subs.fold<double>(0, (sum, s) => sum + s.amount);

    final pdf = pw.Document();

    final headers = [
      'الحالة',
      'تاريخ الانتهاء',
      'تاريخ البداية',
      'المبلغ',
      'نوع العملية',
      'اسم اللاعب',
    ];

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.0),
      1: const pw.FlexColumnWidth(1.4),
      2: const pw.FlexColumnWidth(1.4),
      3: const pw.FlexColumnWidth(1.0),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(2.0),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير الاشتراكات${filter.scopeSuffix}', filter.academyName ?? '', _dateRange(filter)),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _text('إجمالي المبالغ: ${total.toStringAsFixed(0)} ${filter.currencyLabel}',
                  bold: true,
                  size: 11,
                  color: PdfColor.fromHex('#2D9748')),
              _text('إجمالي الاشتراكات: ${subs.length}',
                  bold: true,
                  size: 11,
                  color: PdfColor.fromHex('#1A2B4A')),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children:
                    headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (subs.isEmpty)
                pw.TableRow(
                  children: List.generate(
                    headers.length,
                    (i) => i == 2 ? _cell('لا توجد بيانات') : _cell(''),
                  ),
                )
              else
                ...subs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final rowColor =
                      idx.isOdd ? _altRowColor : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _cell(s.statusLabel),
                      _cell(_fmtDate(s.endDate)),
                      _cell(_fmtDate(s.startDate)),
                      _cell('${s.amount.toStringAsFixed(0)} ${filter.currencyLabel}'),
                      _cell(s.typeLabel),
                      _cell(s.playerName.isNotEmpty ? s.playerName : s.playerId, bold: true),
                    ],
                  );
                }),
              // Summary row
              if (subs.isNotEmpty)
                pw.TableRow(
                  decoration:
                      pw.BoxDecoration(color: PdfColor.fromHex('#FFF3E0')),
                  children: [
                    _cell(''),
                    _cell(''),
                    _cell('الإجمالي', bold: true),
                    _cell('${total.toStringAsFixed(0)} ${filter.currencyLabel}', bold: true),
                    _cell(''),
                    _cell(''),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 3. Revenue Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generateRevenueReport(ReportFilter filter) async {
    await _loadFonts();

    final academyId = filter.academyId ?? '';

    double totalRevenue;
    double monthlyRevenue;
    int newSubs;
    int renewals;
    int activeCount;
    int expiredCount;

    if (filter.sport != null && filter.sport!.isNotEmpty) {
      // Per-sport: compute locally from the sport's subscriptions
      // (players query + subscriptions query — no per-sport loops).
      final subsUC = sl<GetSubscriptionsByAcademyUsecase>();
      final subsResult = await subsUC(
        GetSubscriptionsByAcademyParams(
            academyId: academyId, page: 1, limit: 500),
      );
      var subs = subsResult.fold((_) => [], (r) => r.subscriptions);
      final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
      if (sportIds != null) {
        subs = subs.where((s) => sportIds.contains(s.playerId)).toList();
      }
      final now = DateTime.now();
      totalRevenue = subs.fold<double>(0, (sum, s) => sum + s.amount);
      monthlyRevenue = subs
          .where((s) =>
              s.createdAt.year == now.year && s.createdAt.month == now.month)
          .fold<double>(0, (sum, s) => sum + s.amount);
      newSubs = subs
          .where((s) => s.type == SubscriptionType.newSubscription)
          .length;
      renewals =
          subs.where((s) => s.type == SubscriptionType.renewal).length;
      activeCount = subs.where((s) => s.isActive).length;
      expiredCount = subs.where((s) => !s.isActive).length;
    } else {
      // All sports: use the pre-aggregated revenue summary (single query).
      final revenueUC = sl<GetRevenueSummaryUsecase>();
      final result = await revenueUC(
        GetRevenueSummaryParams(academyId: academyId),
      );
      final data = result.fold((_) => <String, dynamic>{}, (r) => r);
      totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
      monthlyRevenue = (data['monthlyRevenue'] as num?)?.toDouble() ?? 0;
      newSubs = (data['newSubscriptionsCount'] as num?)?.toInt() ?? 0;
      renewals = (data['renewalsCount'] as num?)?.toInt() ?? 0;
      activeCount = (data['activeCount'] as num?)?.toInt() ?? 0;
      expiredCount = (data['expiredCount'] as num?)?.toInt() ?? 0;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader('تقرير الإيرادات${filter.scopeSuffix}', filter.academyName ?? '', _dateRange(filter)),
            pw.SizedBox(height: 24),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _statBox(
                    label: 'إجمالي الإيرادات',
                    value: '${totalRevenue.toStringAsFixed(0)} ${filter.currencyLabel}',
                    color: PdfColor.fromHex('#E85D04'),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _statBox(
                    label: 'إيرادات الشهر الحالي',
                    value: '${monthlyRevenue.toStringAsFixed(0)} ${filter.currencyLabel}',
                    color: PdfColor.fromHex('#2D9748'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _statBox(
                    label: 'اشتراكات جديدة',
                    value: '$newSubs',
                    color: PdfColor.fromHex('#1A2B4A'),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _statBox(
                    label: 'تجديدات',
                    value: '$renewals',
                    color: PdfColor.fromHex('#F59E0B'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _statBox(
                    label: 'اشتراكات نشطة',
                    value: '$activeCount',
                    color: PdfColor.fromHex('#2D9748'),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _statBox(
                    label: 'اشتراكات منتهية',
                    value: '$expiredCount',
                    color: PdfColor.fromHex('#DC2626'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statBox({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _text(label, size: 10, color: PdfColors.white),
          pw.SizedBox(height: 6),
          _text(value, bold: true, size: 20, color: PdfColors.white),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Evaluations Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generateEvaluationsReport(
      ReportFilter filter) async {
    await _loadFonts();

    final academyId = filter.academyId ?? '';
    final evalUC = sl<GetEvaluationsByAcademyUsecase>();

    final result = await evalUC(
      GetEvaluationsByAcademyParams(
        academyId: academyId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        page: 1,
        limit: 500,
      ),
    );

    var evals = result.fold((_) => [], (r) => r.evaluations);
    final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
    if (sportIds != null) {
      evals = evals.where((e) => sportIds.contains(e.playerId)).toList();
    }

    final pdf = pw.Document();

    final headers = [
      'التقدير',
      'المتوسط',
      'الالتزام',
      'الدفاع',
      'الهجوم',
      'المهارات',
      'اللياقة',
      'تاريخ التقييم',
      'اسم اللاعب',
    ];

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.9),
      1: const pw.FlexColumnWidth(0.9),
      2: const pw.FlexColumnWidth(0.9),
      3: const pw.FlexColumnWidth(0.9),
      4: const pw.FlexColumnWidth(0.9),
      5: const pw.FlexColumnWidth(0.9),
      6: const pw.FlexColumnWidth(0.9),
      7: const pw.FlexColumnWidth(1.2),
      8: const pw.FlexColumnWidth(1.8),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير التقييمات${filter.scopeSuffix}', filter.academyName ?? '', _dateRange(filter)),
          pw.SizedBox(height: 16),
          _text('إجمالي التقييمات: ${evals.length}',
              bold: true, size: 11, color: PdfColor.fromHex('#1A2B4A')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children:
                    headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (evals.isEmpty)
                pw.TableRow(
                  children: List.generate(
                    headers.length,
                    (i) => i == 4 ? _cell('لا توجد بيانات') : _cell(''),
                  ),
                )
              else
                ...evals.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final rowColor =
                      idx.isOdd ? _altRowColor : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _cell(e.gradeLabel),
                      _cell(e.average.toStringAsFixed(1)),
                      _cell(e.commitment.toStringAsFixed(1)),
                      _cell(e.defense.toStringAsFixed(1)),
                      _cell(e.attack.toStringAsFixed(1)),
                      _cell(e.basicSkills.toStringAsFixed(1)),
                      _cell(e.fitness.toStringAsFixed(1)),
                      _cell(_fmtDate(e.evaluationDate)),
                      _cell(e.evaluatorName ?? e.playerId, bold: true),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 5. Staff Attendance Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generateStaffAttendanceReport({
    required List<({String fullName, String position, int presentCount, int absentCount})> rows,
    required String academyName,
    required String dateRangeLabel,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final headers = ['عدد الغياب', 'عدد الحضور', 'الوظيفة', 'اسم الموظف'];
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.0),
      1: const pw.FlexColumnWidth(1.0),
      2: const pw.FlexColumnWidth(1.4),
      3: const pw.FlexColumnWidth(2.0),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير حضور الموظفين', academyName, dateRangeLabel),
          pw.SizedBox(height: 16),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children: headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (rows.isEmpty)
                pw.TableRow(children: List.generate(headers.length, (i) => i == 3 ? _cell('لا توجد بيانات') : _cell(''))),
              ...rows.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final rowColor = idx.isOdd ? _altRowColor : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell('${r.absentCount}'),
                    _cell('${r.presentCount}'),
                    _cell(r.position),
                    _cell(r.fullName, bold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 6. Payroll Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generatePayrollReport({
    required List<({String fullName, String position, double baseSalary, double deductionAmount, double netSalary, String status})> rows,
    required String academyName,
    required String monthLabel,
    required String currencyLabel,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final headers = ['الحالة', 'صافي الراتب', 'الخصومات', 'الراتب الأساسي', 'الوظيفة', 'اسم الموظف'];
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.9),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.0),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(1.8),
    };

    final totalNet = rows.fold<double>(0, (sum, r) => sum + r.netSalary);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير الرواتب', academyName, monthLabel),
          pw.SizedBox(height: 16),
          _text('إجمالي صافي الرواتب: ${totalNet.toStringAsFixed(0)} $currencyLabel', bold: true, size: 11, color: PdfColor.fromHex('#2D9748')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children: headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (rows.isEmpty)
                pw.TableRow(children: List.generate(headers.length, (i) => i == 5 ? _cell('لا توجد بيانات') : _cell(''))),
              ...rows.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final rowColor = idx.isOdd ? _altRowColor : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell(r.status == 'paid' ? 'مدفوع' : 'معلق'),
                    _cell('${r.netSalary.toStringAsFixed(0)} $currencyLabel', bold: true),
                    _cell(r.deductionAmount.toStringAsFixed(0)),
                    _cell(r.baseSalary.toStringAsFixed(0)),
                    _cell(r.position),
                    _cell(r.fullName, bold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 7. Expense Report
  // ---------------------------------------------------------------------------

  static Future<Uint8List> generateExpenseReport({
    required List<({String name, String category, double amount, String date})> rows,
    required double totalAmount,
    required Map<String, double> byCategory,
    required String academyName,
    required String dateRangeLabel,
    required String currencyLabel,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final headers = ['التاريخ', 'المبلغ', 'التصنيف', 'اسم المصروف'];
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.2),
      1: const pw.FlexColumnWidth(1.0),
      2: const pw.FlexColumnWidth(1.2),
      3: const pw.FlexColumnWidth(2.0),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          _buildHeader('تقرير المصروفات', academyName, dateRangeLabel),
          pw.SizedBox(height: 16),
          _text('إجمالي المصروفات: ${totalAmount.toStringAsFixed(0)} $currencyLabel', bold: true, size: 11, color: PdfColor.fromHex('#DC2626')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: _tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _headerColor),
                children: headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (rows.isEmpty)
                pw.TableRow(children: List.generate(headers.length, (i) => i == 3 ? _cell('لا توجد بيانات') : _cell(''))),
              ...rows.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final rowColor = idx.isOdd ? _altRowColor : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell(r.date),
                    _cell('${r.amount.toStringAsFixed(0)} $currencyLabel'),
                    _cell(r.category),
                    _cell(r.name, bold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
