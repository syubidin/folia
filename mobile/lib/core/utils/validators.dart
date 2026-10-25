abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email wajib diisi';
    if (!_email.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.length < 8) return 'Minimal 8 karakter';
    return null;
  }
}
