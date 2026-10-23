import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/s.dart';

/// Active language code (`ar` / `fr`).
final localeProvider = StateProvider<String>((ref) => 'ar');

/// All UI strings for the active language.
final sProvider = Provider<S>((ref) => S(ref.watch(localeProvider)));
