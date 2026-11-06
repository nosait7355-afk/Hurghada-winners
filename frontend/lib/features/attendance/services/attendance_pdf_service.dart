import 'dart:typed_data';

import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// توليد تقرير الحضور/الغياب كـ PDF — بنمط خدمة التقارير الحالية (Cairo + RTL).
class AttendancePdfService {
  AttendancePdfService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    _regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static pw.Widget _t(String text,
      {bool bold = false, double size = 10, PdfColor? color}) {
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

  static pw.Widget _cell(String text,
      {bool isHeader = false, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: _t(
        text,
        bold: bold || isHeader,
        size: isHeader ? 9 : 8.5,
        color: isHeader ? PdfColors.white : PdfColors.black,
      ),
    );
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _t(label, size: 9, color: PdfColors.white),
            pw.SizedBox(height: 4),
            _t(value, bold: true, size: 16, color: PdfColors.white),
          ],
        ),
      ),
    );
  }

  static Future<Uint8List> generate({
    required AttendanceReport report,
    required String academyName,
    String? sportLabel,
  }) async {
    await _loadFonts();

    final headerColor = PdfColor.fromHex('#1A2B4A');
    final altRow = PdfColor.fromHex('#F9FAFB');
    final tableBorder =
        pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 0.5);

    final overallRate = report.overallRate;

    final headers = ['نسبة الالتزام', 'الغياب', 'الحضور', 'الرياضة', 'اسم اللاعب', 'الكود'];
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.2),
      1: const pw.FlexColumnWidth(1.0),
      2: const pw.FlexColumnWidth(1.0),
      3: const pw.FlexColumnWidth(1.3),
      4: const pw.FlexColumnWidth(2.2),
      5: const pw.FlexColumnWidth(1.0),
    };

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => [
          // الترويسة
          pw.Container(
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
                    _t('تقرير الحضور والغياب',
                        bold: true, size: 16, color: PdfColors.white),
                    if (sportLabel != null && sportLabel.isNotEmpty)
                      _t('الرياضة: $sportLabel',
                          size: 10, color: PdfColors.white),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _t(academyName,
                        bold: true, size: 12, color: PdfColors.white),
                    _t('حتى ${report.endDate} — من بداية اشتراك كل لاعب',
                        size: 9, color: PdfColors.white),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // بطاقات الملخص
          pw.Row(
            children: [
              _statBox('عدد اللاعبين', '${report.playersCount}',
                  PdfColor.fromHex('#1A2B4A')),
              pw.SizedBox(width: 10),
              _statBox('إجمالي الحضور', '${report.totalPresent}',
                  PdfColor.fromHex('#2D9748')),
              pw.SizedBox(width: 10),
              _statBox('إجمالي الغياب', '${report.totalAbsent}',
                  PdfColor.fromHex('#DC2626')),
              pw.SizedBox(width: 10),
              _statBox('نسبة الالتزام', '$overallRate%',
                  PdfColor.fromHex('#E85D04')),
            ],
          ),
          pw.SizedBox(height: 16),
          // الجدول
          pw.Table(
            border: tableBorder,
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children:
                    headers.map((h) => _cell(h, isHeader: true)).toList(),
              ),
              if (report.rows.isEmpty)
                pw.TableRow(
                  children: List.generate(
                    headers.length,
                    (i) => i == 4 ? _cell('لا توجد بيانات') : _cell(''),
                  ),
                )
              else
                ...report.rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: idx.isOdd ? altRow : PdfColors.white),
                    children: [
                      // المنتهي بلا أرقام — يظهر "منتهي" فقط.
                      _cell(r.isActive ? '${r.rate}%' : 'منتهي'),
                      _cell(r.isActive ? '${r.absent}' : '-'),
                      _cell(r.isActive ? '${r.present}' : '-'),
                      _cell(r.sport ?? '-'),
                      _cell(r.fullName, bold: true),
                      _cell(r.playerCode),
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
