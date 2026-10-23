import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 's.dart';
import '../providers/ui_providers.dart';

/// `context.s` gives the localized strings of the active language.
extension SContext on BuildContext {
  S get s => ProviderScope.containerOf(this, listen: false).read(sProvider);
}
