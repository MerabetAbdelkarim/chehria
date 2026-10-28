import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/s.dart';
import '../../../core/utils/formatters.dart';
import '../../categories/models/category.dart';
import '../../transactions/models/money_transaction.dart';
import '../domain/monthly_report.dart';

/// Builds monthly report files (Excel and PDF, in the user's language) and
/// opens the share sheet.
class ExportService {
  ExportService._();

  /// Shares `chehria-YYYY-MM.xlsx`.
  static Future<void> shareExcel({
    required MonthlyReport report,
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required Map<String, String> accountNames,
    required S s,
  }) async {
    final labels = _Labels(s, categories);
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue(labels.title(report))]);
    sheet.appendRow([
      TextCellValue(s.reportIncome),
      IntCellValue(report.income),
    ]);
    sheet.appendRow([
      TextCellValue(s.reportExpense),
      IntCellValue(report.expense),
    ]);
    sheet.appendRow([TextCellValue(s.reportNet), IntCellValue(report.net)]);
    sheet.appendRow([]);
    sheet.appendRow([
      for (final h in labels.operationHeaders) TextCellValue(h),
    ]);

    for (final txn in _sorted(transactions)) {
      sheet.appendRow([
        TextCellValue(formatDateShort(txn.date)),
        TextCellValue(labels.typeName(txn)),
        TextCellValue(labels.categoryName(txn.categoryId)),
        TextCellValue(accountNames[txn.accountId] ?? ''),
        TextCellValue(txn.note),
        IntCellValue(_signed(txn)),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(s.reportByCategory),
      TextCellValue(s.count),
      TextCellValue(s.amount),
    ]);
    for (final row in report.byCategory) {
      sheet.appendRow([
        TextCellValue(labels.rowName(row)),
        IntCellValue(row.count),
        IntCellValue(row.total),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: ['chehria-${report.monthKey}.xlsx'],
        title: labels.title(report),
      ),
    );
  }

  /// Shares `chehria-YYYY-MM.pdf`, in Arabic (RTL, embedded Amiri font) or
  /// French depending on [s].
  static Future<void> sharePdf({
    required MonthlyReport report,
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required Map<String, String> accountNames,
    required S s,
  }) async {
    final bytes = await buildPdf(
      report: report,
      transactions: transactions,
      categories: categories,
      accountNames: accountNames,
      s: s,
      fonts: await loadPdfFonts(),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'chehria-${report.monthKey}.pdf',
    );
  }

  /// Amiri covers both Arabic and Latin glyphs, so one family serves both
  /// languages (SIL Open Font License, `assets/fonts/OFL.txt`).
  static Future<PdfFonts> loadPdfFonts() async {
    final regular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    return PdfFonts(regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
  }

  /// Renders the PDF bytes (pure: no plugin call, unit-testable).
  static Future<Uint8List> buildPdf({
    required MonthlyReport report,
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required Map<String, String> accountNames,
    required S s,
    required PdfFonts fonts,
  }) async {
    final labels = _Labels(s, categories);
    final direction = s.isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    );

    pw.Widget cell(String text, {bool header = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Text(
        text,
        textDirection: direction,
        style: pw.TextStyle(
          font: header ? fonts.bold : fonts.regular,
          fontSize: 9,
        ),
      ),
    );

    pw.Widget heading(String text, double size) => pw.Text(
      text,
      textDirection: direction,
      style: pw.TextStyle(font: fonts.bold, fontSize: size),
    );

    final currency = s.isAr ? 'دج' : 'DA';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: direction,
        build: (context) => [
          heading(labels.title(report), 16),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryBox(s.reportIncome, report.income, currency, fonts),
              _summaryBox(s.reportExpense, report.expense, currency, fonts),
              _summaryBox(s.reportNet, report.net, currency, fonts),
            ],
          ),
          pw.SizedBox(height: 18),
          heading(s.reportByCategory, 12),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            children: [
              pw.TableRow(
                children: [
                  cell(s.category, header: true),
                  cell(s.count, header: true),
                  cell('${s.amount} ($currency)', header: true),
                ],
              ),
              for (final row in report.byCategory)
                pw.TableRow(
                  children: [
                    cell(labels.rowName(row)),
                    cell('${row.count}'),
                    cell(groupNumber(row.total)),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 18),
          heading('${s.reportOperations} (${report.operationsCount})', 12),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            children: [
              pw.TableRow(
                children: [
                  for (final h in labels.operationHeaders)
                    cell(h, header: true),
                ],
              ),
              for (final txn in _sorted(transactions))
                pw.TableRow(
                  children: [
                    cell(formatDateShort(txn.date)),
                    cell(labels.typeName(txn)),
                    cell(labels.categoryName(txn.categoryId)),
                    cell(accountNames[txn.accountId] ?? ''),
                    cell(txn.note),
                    cell(
                      (_signed(txn) < 0 ? '-' : '') + groupNumber(txn.amount),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static List<MoneyTransaction> _sorted(List<MoneyTransaction> txns) =>
      [...txns]..sort((a, b) => a.date.compareTo(b.date));

  static int _signed(MoneyTransaction t) =>
      t.isExpense || t.isTransfer ? -t.amount : t.amount;

  static pw.Widget _summaryBox(
    String label,
    int amount,
    String currency,
    PdfFonts fonts,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(font: fonts.regular, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${groupNumber(amount)} $currency',
            style: pw.TextStyle(font: fonts.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Fonts embedded in the PDF.
class PdfFonts {
  const PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

/// Localized labels shared by both export formats.
class _Labels {
  _Labels(this.s, this.categories);

  final S s;
  final List<Category> categories;

  String title(MonthlyReport report) {
    final parts = report.monthKey.split('-');
    final month = monthLabel(
      int.parse(parts[0]),
      int.parse(parts[1]),
      isAr: s.isAr,
    );
    return '${s.appName} — $month';
  }

  List<String> get operationHeaders => [
    s.date,
    s.type,
    s.category,
    s.account,
    s.note,
    s.amount,
  ];

  String categoryName(String? id) {
    if (id == null || id.isEmpty) return s.uncategorized;
    for (final c in categories) {
      if (c.id == id) return c.name(isAr: s.isAr);
    }
    return s.uncategorized;
  }

  String rowName(CategoryReportRow row) {
    final name = s.isAr ? row.name : row.nameFr;
    return name.isEmpty ? s.uncategorized : name;
  }

  String typeName(MoneyTransaction t) {
    if (t.isTransfer) return s.transferShort;
    if (t.isIncome) return s.incomeShort;
    return s.expense;
  }
}
