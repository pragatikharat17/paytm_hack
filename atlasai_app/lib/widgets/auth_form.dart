import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';

enum AuthFormMode { login, register, reset }

class AuthForm extends StatefulWidget {
  final AuthFormMode mode;
  const AuthForm({super.key, required this.mode});
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;
  bool _resetSent = false;
  bool get _register => widget.mode == AuthFormMode.register;
  bool get _reset => widget.mode == AuthFormMode.reset;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = AuthScope.of(context);
    try {
      if (_reset) {
        await service.resetPassword(_email.text);
        if (mounted) setState(() => _resetSent = true);
      } else if (_register) {
        await service.register(_email.text, _password.text);
      } else {
        await service.login(_email.text, _password.text);
      }
      // AuthGate responds to authStateChanges and opens the existing app.
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _reset
        ? 'Reset password'
        : _register
        ? 'Create account'
        : 'Welcome to AtlasAI';
    return Scaffold(
      appBar: AppBar(title: const Text('AtlasAI Paytm')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 44,
                        color: AppTheme.brandBlue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _reset
                            ? 'We’ll email you a link to reset your password.'
                            : 'Sign in to your payment support account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: _reset
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autocorrect: false,
                        validator: (value) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Enter a valid email address.',
                      ),
                      if (!_reset) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _hidden,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: _hidden
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(
                                _hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value ?? '').isEmpty
                              ? 'Enter your password.'
                              : _register && value!.length < 8
                              ? 'Use at least 8 characters.'
                              : null,
                        ),
                        if (_register) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirm,
                            enabled: !_busy,
                            obscureText: _hidden,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                            ),
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (value) => value == _password.text
                                ? null
                                : 'Passwords do not match.',
                          ),
                        ],
                      ],
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.roseDanger),
                          ),
                        ),
                      if (_resetSent)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'If an account exists for this email, a reset link has been sent. Check your inbox.',
                            style: TextStyle(color: AppTheme.emeraldSuccess),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _reset
                                    ? 'Send reset link'
                                    : _register
                                    ? 'Create account'
                                    : 'Sign in',
                              ),
                      ),
                      if (!_register && !_reset) ...[
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                          child: const Text('Forgot password?'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: const Text('Create an account'),
                        ),
                      ] else
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Back to sign in'),
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
