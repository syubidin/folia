import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folia/core/utils/validators.dart';
import 'package:folia/l10n/generated/app_localizations.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  test('email validator', () {
    final v = Validators.email(l);
    expect(v(''), isNotNull);
    expect(v('abc'), isNotNull);
    expect(v('a@b.co'), isNull);
  });

  test('password validator', () {
    final v = Validators.password(l);
    expect(v('short'), isNotNull);
    expect(v('panjang123'), isNull);
  });
}
