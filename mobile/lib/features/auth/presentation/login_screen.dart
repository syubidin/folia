import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/core/theme/app_colors.dart';
import 'package:folia/core/utils/failure_l10n.dart';
import 'package:folia/core/utils/l10n_x.dart';
import 'package:folia/core/utils/validators.dart';
import 'package:folia/features/auth/presentation/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final l10n = context.l10n;

    if (_isSignUp) {
      final r = await controller.signUp(_email.text, _password.text);
      if (!mounted) return;
      switch (r) {
        case Ok(:final value) when value:
          _toast(l10n.signUpCheckEmail);
        case Ok():
          break;
        case Err(:final failure):
          _toast(failure.localized(l10n));
      }
    } else {
      final r = await controller.signIn(_email.text, _password.text);
      if (!mounted) return;
      if (r case Err(:final failure)) _toast(failure.localized(l10n));
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Folia', style: text.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _isSignUp ? l10n.signUpSubtitle : l10n.signInSubtitle,
                        style: text.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.email),
                        validator: Validators.email(l10n),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [
                          if (_isSignUp)
                            AutofillHints.newPassword
                          else
                            AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: Validators.password(l10n),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isSignUp ? l10n.signUp : l10n.signIn),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? l10n.haveAccount : l10n.noAccount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
