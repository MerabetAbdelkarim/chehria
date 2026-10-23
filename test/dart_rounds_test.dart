import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/features/dart/models/dart_group.dart';

DartGroup makeGroup({
  int currentRound = 1,
  List<DartPayment> payments = const [],
}) => DartGroup(
  id: 'g1',
  name: 'دَّارة الأصدقاء',
  contributionAmount: 2000,
  memberNames: const ['أنا', 'محمد', 'علي'],
  meName: 'أنا',
  currentRound: currentRound,
  startDate: DateTime(2026, 10, 1),
  payments: payments,
);

void main() {
  group('DartGroup rotation', () {
    test('pot is contribution times members', () {
      expect(makeGroup().pot, 6000);
    });

    test('receiverOf rotates through members', () {
      final g = makeGroup();
      expect(g.receiverOf(1), 'أنا');
      expect(g.receiverOf(2), 'محمد');
      expect(g.receiverOf(3), 'علي');
      expect(g.receiverOf(4), 'أنا');
    });

    test('nextReceiver follows currentRound', () {
      expect(makeGroup(currentRound: 2).nextReceiver, 'محمد');
    });

    test('isFinished after the last member received', () {
      expect(makeGroup(currentRound: 3).isFinished, isFalse);
      expect(makeGroup(currentRound: 4).isFinished, isTrue);
    });

    test('roundsDone is currentRound minus one, never negative', () {
      expect(makeGroup(currentRound: 1).roundsDone, 0);
      expect(makeGroup(currentRound: 3).roundsDone, 2);
    });
  });

  group('DartGroup payments', () {
    test('hasPaid matches member and round', () {
      final g = makeGroup().copyWithPayments([
        DartPayment(memberName: 'محمد', round: 1, date: DateTime(2026, 10, 2)),
      ]);

      expect(g.hasPaid('محمد', 1), isTrue);
      expect(g.hasPaid('محمد', 2), isFalse);
      expect(g.hasPaid('أنا', 1), isFalse);
    });

    test('unpaidMembers lists everyone who has not paid the current round', () {
      final g = makeGroup(currentRound: 2).copyWithPayments([
        DartPayment(memberName: 'محمد', round: 2, date: DateTime(2026, 11, 2)),
      ]);
      expect(g.unpaidMembers, ['أنا', 'علي']);
    });
  });
}

extension on DartGroup {
  DartGroup copyWithPayments(List<DartPayment> payments) => DartGroup(
    id: id,
    name: name,
    contributionAmount: contributionAmount,
    memberNames: memberNames,
    meName: meName,
    currentRound: currentRound,
    startDate: startDate,
    payments: payments,
    createdAt: createdAt,
  );
}
