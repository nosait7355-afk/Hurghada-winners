import 'dart:typed_data';

import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/reports/domain/models/report_filter.dart';
import 'package:hurghada_winners/features/reports/services/report_sport_filter.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluations_by_academy_usecase.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ExcelReportService {
  ExcelReportService._();

  // ── style helpers ──────────────────────────────────────────────────────────

  static CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A2B4A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle _altRowStyle() => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F9FAFB'),
      );

  static CellStyle _totalStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E85D04'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

  static void _setCell(Sheet sheet, int row, int col, Object? value,
      {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: col,
      rowIndex: row,
    ));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else {
      cell.value = TextCellValue(value?.toString() ?? '');
    }
    if (style != null) cell.cellStyle = style;
  }

  static void _setHeaders(Sheet sheet, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 0, i, headers[i], style: _headerStyle());
      sheet.setColumnWidth(i, 22);
    }
  }

  static String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'ar').format(d);

  // ── share ──────────────────────────────────────────────────────────────────

  static Future<void> shareExcel(Uint8List bytes, String fileName) async {
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: fileName,
    );
  }

  // ── 1. Players Report ──────────────────────────────────────────────────────

  static Future<Uint8List> generatePlayersExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getPlayers = sl<GetPlayersUsecase>();
    final getSubs = sl<GetSubscriptionsByAcademyUsecase>();

    final playersResult = await getPlayers(
      GetPlayersParams(
          academyId: filter.academyId,
          sport: filter.sport,
          groupId: filter.groupId,
          page: 1,
          limit: 500),
    );
    final players = playersResult.fold((_) => [], (v) => v.players);

    final subsResult = await getSubs(
      GetSubscriptionsByAcademyParams(
        academyId: filter.academyId!,
        page: 1,
        limit: 500,
      ),
    );
    var subs = subsResult.fold((_) => [], (v) => v.subscriptions);
    // Scope subscriptions to the same sport as the players above.
    final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
    if (sportIds != null) {
      subs = subs.where((s) => sportIds.contains(s.playerId)).toList();
    }
    // كل اللاعبين الذين لديهم أي اشتراك (نشط أو منتهي)
    final allSubscribedPlayerIds = subs.map((s) => s.playerId).toSet();
    // اللاعبون الذين لديهم اشتراك نشط حالياً
    final activePlayerIds = subs
        .where((s) => s.isActive)
        .map((s) => s.playerId)
        .toSet();

    final excel = Excel.createExcel();
    final sheet = excel['اللاعبون${filter.scopeSuffix}'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'الكود',
      'الاسم',
      'تاريخ الميلاد',
      'اسم ولي الأمر',
      'مهنة ولي الأمر',
      'رقم الهاتف',
      'حالة الاشتراك',
    ]);

    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      final status = activePlayerIds.contains(p.id)
          ? 'نشط'
          : allSubscribedPlayerIds.contains(p.id)
              ? 'منتهي'
              : 'جديد';

      _setCell(sheet, row, 0, p.playerCode, style: style);
      _setCell(sheet, row, 1, p.fullName, style: style);
      _setCell(sheet, row, 2, _fmtDate(p.birthDate), style: style);
      _setCell(sheet, row, 3, p.parentName, style: style);
      _setCell(sheet, row, 4, p.parentJob ?? '-', style: style);
      _setCell(sheet, row, 5, p.parentPhone, style: style);
      _setCell(sheet, row, 6, status, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 2. Subscriptions Report ────────────────────────────────────────────────

  static Future<Uint8List> generateSubscriptionsExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getSubs = sl<GetSubscriptionsByAcademyUsecase>();

    final result = await getSubs(
      GetSubscriptionsByAcademyParams(
        academyId: filter.academyId!,
        status: filter.subscriptionStatus,
        page: 1,
        limit: 500,
      ),
    );
    var subs = result.fold((_) => [], (v) => v.subscriptions);
    final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
    if (sportIds != null) {
      subs = subs.where((s) => sportIds.contains(s.playerId)).toList();
    }

    final excel = Excel.createExcel();
    final sheet = excel['الاشتراكات${filter.scopeSuffix}'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'اسم اللاعب',
      'نوع العملية',
      'المبلغ (${filter.currencyLabel})',
      'تاريخ البداية',
      'تاريخ الانتهاء',
      'الحالة',
    ]);

    double total = 0;
    for (var i = 0; i < subs.length; i++) {
      final s = subs[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      total += s.amount;

      _setCell(sheet, row, 0, s.playerName.isNotEmpty ? s.playerName : s.playerId, style: style);
      _setCell(sheet, row, 1, s.typeLabel, style: style);
      _setCell(sheet, row, 2, s.amount, style: style);
      _setCell(sheet, row, 3, _fmtDate(s.startDate), style: style);
      _setCell(sheet, row, 4, _fmtDate(s.endDate), style: style);
      _setCell(sheet, row, 5, s.statusLabel, style: style);
    }

    // Total row
    if (subs.isNotEmpty) {
      final totalRow = subs.length + 1;
      _setCell(sheet, totalRow, 0, 'الإجمالي', style: _totalStyle());
      _setCell(sheet, totalRow, 2, total, style: _totalStyle());
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 3. Revenue Report ──────────────────────────────────────────────────────

  static Future<Uint8List> generateRevenueExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    double totalRevenue;
    double monthlyRevenue;
    int newSubs;
    int renewals;
    int activeCount;
    int expiredCount;

    if (filter.sport != null && filter.sport!.isNotEmpty) {
      final getSubs = sl<GetSubscriptionsByAcademyUsecase>();
      final subsResult = await getSubs(
        GetSubscriptionsByAcademyParams(
            academyId: filter.academyId!, page: 1, limit: 500),
      );
      var subs = subsResult.fold((_) => [], (v) => v.subscriptions);
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
      newSubs =
          subs.where((s) => s.type == SubscriptionType.newSubscription).length;
      renewals = subs.where((s) => s.type == SubscriptionType.renewal).length;
      activeCount = subs.where((s) => s.isActive).length;
      expiredCount = subs.where((s) => !s.isActive).length;
    } else {
      final getRevenue = sl<GetRevenueSummaryUsecase>();
      final result = await getRevenue(
        GetRevenueSummaryParams(academyId: filter.academyId!),
      );
      final data = result.fold((_) => <String, dynamic>{}, (v) => v);
      totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
      monthlyRevenue = (data['monthlyRevenue'] as num?)?.toDouble() ?? 0;
      newSubs = (data['newSubscriptionsCount'] as num?)?.toInt() ?? 0;
      renewals = (data['renewalsCount'] as num?)?.toInt() ?? 0;
      activeCount = (data['activeCount'] as num?)?.toInt() ?? 0;
      expiredCount = (data['expiredCount'] as num?)?.toInt() ?? 0;
    }

    final excel = Excel.createExcel();
    final sheet = excel['الإيرادات${filter.scopeSuffix}'];
    excel.delete('Sheet1');

    _setHeaders(sheet, ['البيان', 'القيمة']);
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 20);

    final rows = [
      ['إجمالي الإيرادات (${filter.currencyLabel})', totalRevenue],
      ['إيرادات الشهر الحالي (${filter.currencyLabel})', monthlyRevenue],
      ['عدد الاشتراكات الجديدة', newSubs],
      ['عدد التجديدات', renewals],
      ['الاشتراكات النشطة', activeCount],
      ['الاشتراكات المنتهية', expiredCount],
    ];

    for (var i = 0; i < rows.length; i++) {
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      _setCell(sheet, row, 0, rows[i][0], style: style);
      _setCell(sheet, row, 1, rows[i][1], style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 4. Evaluations Report ──────────────────────────────────────────────────

  static Future<Uint8List> generateEvaluationsExcel(ReportFilter filter) async {
    if (filter.academyId == null) throw Exception('academyId مطلوب');

    final getEvals = sl<GetEvaluationsByAcademyUsecase>();
    final result = await getEvals(
      GetEvaluationsByAcademyParams(
        academyId: filter.academyId!,
        startDate: filter.startDate,
        endDate: filter.endDate,
        limit: 500,
      ),
    );
    var evals = result.fold((_) => [], (v) => v.evaluations);
    final sportIds = await playerIdsForSport(filter.academyId, filter.sport, filter.groupId);
    if (sportIds != null) {
      evals = evals.where((e) => sportIds.contains(e.playerId)).toList();
    }

    final excel = Excel.createExcel();
    final sheet = excel['التقييمات${filter.scopeSuffix}'];
    excel.delete('Sheet1');

    _setHeaders(sheet, [
      'اسم اللاعب',
      'تاريخ التقييم',
      'اللياقة',
      'المهارات الأساسية',
      'الهجوم',
      'الدفاع',
      'الالتزام',
      'المتوسط',
      'التقدير',
    ]);

    for (var i = 0; i < evals.length; i++) {
      final e = evals[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();

      _setCell(sheet, row, 0, e.evaluatorName ?? e.playerId, style: style);
      _setCell(sheet, row, 1, _fmtDate(e.evaluationDate), style: style);
      _setCell(sheet, row, 2, e.fitness, style: style);
      _setCell(sheet, row, 3, e.basicSkills, style: style);
      _setCell(sheet, row, 4, e.attack, style: style);
      _setCell(sheet, row, 5, e.defense, style: style);
      _setCell(sheet, row, 6, e.commitment, style: style);
      _setCell(sheet, row, 7, e.average, style: style);
      _setCell(sheet, row, 8, e.gradeLabel, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 5. Staff Attendance Report ─────────────────────────────────────────────

  static Future<Uint8List> generateStaffAttendanceExcel(
    List<({String fullName, String position, int presentCount, int absentCount})> rows,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['حضور الموظفين'];
    excel.delete('Sheet1');

    _setHeaders(sheet, ['اسم الموظف', 'الوظيفة', 'عدد الحضور', 'عدد الغياب']);

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      _setCell(sheet, row, 0, r.fullName, style: style);
      _setCell(sheet, row, 1, r.position, style: style);
      _setCell(sheet, row, 2, r.presentCount, style: style);
      _setCell(sheet, row, 3, r.absentCount, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 6. Payroll Report ───────────────────────────────────────────────────────

  static Future<Uint8List> generatePayrollExcel(
    List<({String fullName, String position, double baseSalary, double deductionAmount, double netSalary, String status})> rows,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['الرواتب'];
    excel.delete('Sheet1');

    _setHeaders(sheet, ['اسم الموظف', 'الوظيفة', 'الراتب الأساسي', 'الخصومات', 'صافي الراتب', 'الحالة']);

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      _setCell(sheet, row, 0, r.fullName, style: style);
      _setCell(sheet, row, 1, r.position, style: style);
      _setCell(sheet, row, 2, r.baseSalary, style: style);
      _setCell(sheet, row, 3, r.deductionAmount, style: style);
      _setCell(sheet, row, 4, r.netSalary, style: style);
      _setCell(sheet, row, 5, r.status == 'paid' ? 'مدفوع' : 'معلق', style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }

  // ── 7. Expense Report ───────────────────────────────────────────────────────

  static Future<Uint8List> generateExpenseExcel(
    List<({String name, String category, double amount, String date})> rows,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['المصروفات'];
    excel.delete('Sheet1');

    _setHeaders(sheet, ['اسم المصروف', 'التصنيف', 'المبلغ', 'التاريخ']);

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final row = i + 1;
      final style = row.isOdd ? null : _altRowStyle();
      _setCell(sheet, row, 0, r.name, style: style);
      _setCell(sheet, row, 1, r.category, style: style);
      _setCell(sheet, row, 2, r.amount, style: style);
      _setCell(sheet, row, 3, r.date, style: style);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    return Uint8List.fromList(bytes);
  }
}
