import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chehria/core/constants/app_constants.dart';
import 'package:chehria/core/constants/default_data.dart';

void main() {
  test('every seeded category icon resolves to a constant icon', () {
    for (final category in DefaultData.categories) {
      expect(
        DefaultData.iconOf(category.iconCode).codePoint,
        category.iconCode,
        reason: category.id,
      );
    }
  });

  test('unknown icon codes fall back instead of failing', () {
    expect(DefaultData.iconOf(-1), Icons.category);
  });

  test('every system category is seeded', () {
    final ids = DefaultData.categories.map((c) => c.id).toSet();
    expect(ids, containsAll(AppConstants.systemCategoryIds));
  });
}
