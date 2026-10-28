import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/localization/s.dart';
import 'package:chehria/features/reports/data/export_service.dart';
import 'package:chehria/features/reports/domain/monthly_report.dart';
import 'package:chehria/features/transactions/models/money_transaction.dart';
import 'package:pdf/widgets.dart' as pw;

PdfFonts loadFonts() {
  pw.Font font(String name) => pw.Font.ttf(
    File('assets/fonts/$name').readAsBytesSync().buffer.asByteData(),
  );
  return PdfFonts(
    regular: font('Amiri-Regular.ttf'),
    bold: font('Amiri-Bold.ttf'),
  );
}

void main() {
  final txns = [
    MoneyTransaction(
      id: 't1',
      type: TxnType.expense,
      amount: 2500,
      date: DateTime(2026, 10, 3),
      categoryId: 'cat_food',
      accountId: 'cash',
      note: 'قهوة مع الأصدقاء',
    ),
  ];
  final report = buildMonthlyReport(
    monthKey: '2026-10',
    transactions: txns,
    categories: const [],
  );

  for (final locale in ['ar', 'fr']) {
    test('builds a valid PDF in $locale', () async {
      final bytes = await ExportService.buildPdf(
        report: report,
        transactions: txns,
        categories: const [],
        accountNames: const {'cash': 'نقد'},
        s: S(locale),
        fonts: loadFonts(),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  }
}
