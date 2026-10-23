/// Input validation returning **localized** Arabic/French messages.
library;

import '../constants/app_constants.dart';
import '../localization/s.dart';

final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? validateRequired(S s, String value, String fieldName) {
  if (value.trim().isEmpty) return s.fieldRequired(fieldName);
  return null;
}

String? validateEmail(S s, String value) {
  final v = value.trim();
  if (v.isEmpty) return s.fieldRequired(s.email);
  if (!_emailRe.hasMatch(v)) return s.invalidEmail;
  return null;
}

String? validatePassword(S s, String value) {
  if (value.isEmpty) return s.fieldRequired(s.password);
  if (value.length < 6) return s.passwordTooShort;
  return null;
}

String? validateConfirmPassword(S s, String password, String confirm) {
  if (confirm != password) return s.passwordsDoNotMatch;
  return null;
}

String? validateAmount(S s, String value) {
  final v = value.trim().replaceAll(RegExp(r'[^\d-]'), '');
  if (v.isEmpty) return s.fieldRequired(s.amount);
  final amount = int.tryParse(v);
  if (amount == null || amount <= 0) return s.invalidAmount;
  if (amount > AppConstants.maxAmount) return s.amountTooLarge;
  return null;
}

String? validatePayday(S s, String value) {
  final day = int.tryParse(value.trim());
  if (day == null ||
      day < AppConstants.minPayday ||
      day > AppConstants.maxPayday) {
    return s.invalidPayday;
  }
  return null;
}

String? validateName(S s, String value, String fieldName) {
  if (value.trim().isEmpty) return s.fieldRequired(fieldName);
  if (value.trim().length > 60) return s.tooLong;
  return null;
}
