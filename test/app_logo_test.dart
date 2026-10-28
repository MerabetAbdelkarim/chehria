import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/widgets/app_logo.dart';

void main() {
  testWidgets('the logo paints at the requested size', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: AppLogo(size: 76)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppLogo)), const Size(76, 76));
    expect(find.bySemanticsLabel('Chehria'), findsOneWidget);
  });
}
