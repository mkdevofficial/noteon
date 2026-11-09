import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final name = _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : email.split('@').first;
      final result = await authRepo.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: name,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result.isSuccess) {
        context.go('/notes');
      } else {
        _showError(result.exceptionOrNull?.message ?? 'Sign up failed');
      }
    } else {
      final result = await authRepo.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result.isSuccess) {
        context.go('/notes');
      } else {
        _showError(result.exceptionOrNull?.message ?? 'Sign in failed');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess) {
      context.go('/notes');
    } else {
      _showError(result.exceptionOrNull?.message ?? 'Google Sign In failed');
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInAnonymously();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess) {
      context.go('/notes');
    } else {
      _showError(result.exceptionOrNull?.message ?? 'Anonymous login failed');
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.forgotPassword ?? 'Forgot Password?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n?.email ?? 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(ctx);
                final authRepo = ref.read(authRepositoryProvider);
                final res = await authRepo.sendPasswordResetEmail(email);
                if (mounted) {
                  if (res.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.resetEmailSent ?? 'Password reset email sent!',
                        ),
                      ),
                    );
                  } else {
                    _showError(
                      res.exceptionOrNull?.message ??
                          'Failed to send reset email',
                    );
                  }
                }
              }
            },
            child: Text(l10n?.sendResetLink ?? 'Send Link'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo & Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.note_alt_rounded,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.appName ?? 'NoteOn',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n?.appTagline ?? 'Cloud Notes & Tasks',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      _isSignUp
                          ? (l10n?.signUp ?? 'Create Account')
                          : (l10n?.signIn ?? 'Welcome Back'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Display Name (if sign up)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n?.displayName ?? 'Display Name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n?.email ?? 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return l10n?.invalidEmail ?? 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitEmailPassword(),
                      decoration: InputDecoration(
                        labelText: l10n?.password ?? 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return l10n?.passwordTooShort ??
                              'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    if (!_isSignUp) ...[
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            l10n?.forgotPassword ?? 'Forgot Password?',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 20),

                    // Submit Button
                    FilledButton(
                      onPressed: _isLoading ? null : _submitEmailPassword,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp
                                  ? (l10n?.signUp ?? 'Sign Up')
                                  : (l10n?.signIn ?? 'Sign In'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Sign Up / Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? (l10n?.alreadyHaveAccount ??
                                    'Already have an account?')
                              : (l10n?.dontHaveAccount ??
                                    "Don't have an account?"),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isSignUp = !_isSignUp);
                          },
                          child: Text(
                            _isSignUp
                                ? (l10n?.signIn ?? 'Sign In')
                                : (l10n?.signUp ?? 'Sign Up'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign In
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(l10n?.googleSignIn ?? 'Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Anonymous "Continue without account"
                    TextButton(
                      onPressed: _isLoading ? null : _signInAnonymously,
                      child: Text(
                        l10n?.continueWithoutAccount ??
                            'Continue without account',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
