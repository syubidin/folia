import 'package:flutter_test/flutter_test.dart';
import 'package:folia/core/utils/validators.dart';

void main() {
  test('email validator', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('abc'), isNotNull);
    expect(Validators.email('a@b.co'), isNull);
  });

  test('password validator', () {
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password('panjang123'), isNull);
  });
}
