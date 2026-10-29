import 'package:folia/l10n/generated/app_localizations.dart';

abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? Function(String?) email(AppLocalizations l) => (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return l.emailRequired;
        if (!_email.hasMatch(value)) return l.emailInvalid;
        return null;
      };

  static String? Function(String?) password(AppLocalizations l) => (v) {
        if (v == null || v.length < 8) return l.passwordTooShort;
        return null;
      };

  static String? Function(String?) required(String message) => (v) {
        if (v == null || v.trim().isEmpty) return message;
        return null;
      };
}
