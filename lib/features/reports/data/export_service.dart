import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../categories/models/category.dart';
import '../../transactions/models/money_transaction.dart';
import '../domain/monthly_report.dart';

/// Builds monthly report files (Excel with Arabic labels, PDF in French with
/// built-in fonts so nothing renders as tofu) and opens the share sheet.
class ExportService {
  ExportService._();

  /// Shares `masarifi-YYYY-MM.xlsx`.
  static Future<void> shareExcel({
    required MonthlyReport report,
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required Map<String, String> accountNames,
    required bool isAr,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    String categoryName(String? id) {
      if (id == null || id.isEmpty) return isAr ? 'غير مصنّف' : 'Non classé';
      for (final c in categories) {
        if (c.id == id) return c.name(isAr: isAr);
      }
      return isAr ? 'غير مصنّف' : 'Non classé';
    }

    String typeName(MoneyTransaction t) {
      if (t.isTransfer) return isAr ? 'تحويل' : 'Virement';
      if (t.isIncome) return isAr ? 'دخل' : 'Revenu';
      return isAr ? 'مصروف' : 'Dépense';
    }

    final parts = report.monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final title = isAr
        ? 'مصاريفي — ${monthLabel(year, month, isAr: true)}'
        : 'Masarifi — ${monthLabel(year, month, isAr: false)}';

    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([
      TextCellValue(isAr ? 'إجمالي الدخل' : 'Total revenus'),
      IntCellValue(report.income),
    ]);
    sheet.appendRow([
      TextCellValue(isAr ? 'إجمالي المصاريف' : 'Total dépenses'),
      IntCellValue(report.expense),
    ]);
    sheet.appendRow([
      TextCellValue(isAr ? 'الصافي' : 'Épargne nette'),
      IntCellValue(report.net),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(isAr ? 'التاريخ' : 'Date'),
      TextCellValue(isAr ? 'النوع' : 'Type'),
      TextCellValue(isAr ? 'الفئة' : 'Catégorie'),
      TextCellValue(isAr ? 'الحساب' : 'Compte'),
      TextCellValue(isAr ? 'ملاحظة' : 'Note'),
      TextCellValue(isAr ? 'المبلغ' : 'Montant'),
    ]);

    final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
    for (final txn in sorted) {
      sheet.appendRow([
        TextCellValue(formatDateShort(txn.date)),
        TextCellValue(typeName(txn)),
        TextCellValue(categoryName(txn.categoryId)),
        TextCellValue(accountNames[txn.accountId] ?? ''),
        TextCellValue(txn.note),
        IntCellValue(
          txn.isExpense || txn.isTransfer ? -txn.amount : txn.amount,
        ),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(isAr ? 'حسب الفئة' : 'Par catégorie'),
      TextCellValue(isAr ? 'العدد' : 'Nombre'),
      TextCellValue(isAr ? 'المبلغ' : 'Montant'),
    ]);
    for (final row in report.byCategory) {
      sheet.appendRow([
        TextCellValue(
          row.name.isEmpty ? (isAr ? 'غير مصنّف' : 'Non classé') : row.name,
        ),
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
        fileNameOverrides: ['masarifi-${report.monthKey}.xlsx'],
        title: title,
      ),
    );
  }

  /// Shares `masarifi-YYYY-MM.pdf`.
  ///
  /// PDF text is **French only**: the package's built-in fonts have no Arabic
  /// glyphs. Category names therefore use `nameFr`.
  static Future<void> sharePdf({
    required MonthlyReport report,
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required Map<String, String> accountNames,
  }) async {
    String categoryName(String? id) {
      if (id == null || id.isEmpty) return 'Non classé';
      for (final c in categories) {
        if (c.id == id) return c.nameFr;
      }
      return 'Non classé';
    }

    String typeName(MoneyTransaction t) {
      if (t.isTransfer) return 'Virement';
      if (t.isIncome) return 'Revenu';
      return 'Dépense';
    }

    final parts = report.monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final monthFr = monthLabel(year, month, isAr: false);

    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();

    pw.Widget cell(String text, {bool boldCell = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldCell ? bold : null, fontSize: 9),
      ),
    );

    final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Masarifi — Rapport de $monthFr',
            style: pw.TextStyle(font: bold, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryBox('Revenus', report.income, bold),
              _summaryBox('Dépenses', report.expense, bold),
              _summaryBox('Net', report.net, bold),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Par catégorie',
            style: pw.TextStyle(font: bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            children: [
              pw.TableRow(
                children: [
                  cell('Catégorie', boldCell: true),
                  cell('Nombre', boldCell: true),
                  cell('Montant (DA)', boldCell: true),
                ],
              ),
              for (final row in report.byCategory)
                pw.TableRow(
                  children: [
                    cell(row.nameFr.isEmpty ? 'Non classé' : row.nameFr),
                    cell('${row.count}'),
                    cell(groupNumber(row.total)),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Opérations (${report.operationsCount})',
            style: pw.TextStyle(font: bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            children: [
              pw.TableRow(
                children: [
                  cell('Date', boldCell: true),
                  cell('Type', boldCell: true),
                  cell('Catégorie', boldCell: true),
                  cell('Compte', boldCell: true),
                  cell('Note', boldCell: true),
                  cell('Montant', boldCell: true),
                ],
              ),
              for (final txn in sorted)
                pw.TableRow(
                  children: [
                    cell(formatDateShort(txn.date)),
                    cell(typeName(txn)),
                    cell(categoryName(txn.categoryId)),
                    cell(accountNames[txn.accountId] ?? ''),
                    cell(txn.note),
                    cell(
                      (txn.isExpense || txn.isTransfer ? '-' : '') +
                          groupNumber(txn.amount),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'masarifi-${report.monthKey}.pdf',
    );
  }

  static pw.Widget _summaryBox(String label, int amount, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${groupNumber(amount)} DA',
            style: pw.TextStyle(font: bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
