// lib/utils/app_localizations_ext.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Give BuildContext a `.l10n` shortcut to your generated translations.
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
