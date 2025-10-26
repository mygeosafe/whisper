import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  static const routeName = 'auth';

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the privacy notice to continue.'),
        ),
      );
      return;
    }
    final controller = ref.read(authActionControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isLoginMode) {
      await controller.signIn(email: email, password: password);
    } else {
      await controller.signUp(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authActionControllerProvider);
    final isLoading = actionState.isLoading;
    final errorMessage = actionState.whenOrNull(
      error: (error, _) {
        if (error is AuthException) {
          return error.message;
        }
        return error is Exception ? error.toString() : 'Authentication failed';
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Sign in securely' : 'Create a secure account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All notes and audio are encrypted in transit and stored in your '
                    'personal Supabase space hosted in the EU. You can export or delete '
                    'your data at any time from Settings to meet GDPR requirements.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 12) {
                              return 'Use at least 12 characters for a strong password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _privacyAccepted,
                          onChanged: (value) => setState(() => _privacyAccepted = value ?? false),
                          title: const Text(
                            'I confirm that I have read the privacy notice and consent to '
                            'Whispair processing my personal data in accordance with GDPR.',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: isLoading
                                  ? const CircularProgressIndicator.adaptive()
                                  : Text(_isLoginMode ? 'Sign in' : 'Create account'),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => setState(() => _isLoginMode = !_isLoginMode),
                          child: Text(
                            _isLoginMode
                                ? 'Need an account? Register securely'
                                : 'Have an account? Sign in',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
