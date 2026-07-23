import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>_\-]).{8,}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await AuthService.resetPassword(
      _token.text.trim(),
      _password.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Mot de passe reinitialise')),
      );
      context.go('/login');
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Reinitialisation impossible',
        isAuthError: result.isAuthError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomInput(
                label: 'Token recu par email',
                icon: Icons.vpn_key_outlined,
                controller: _token,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Nouveau mot de passe',
                icon: Icons.lock_outline_rounded,
                controller: _password,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (!_passwordRegex.hasMatch(v)) {
                    return '8 caracteres min, majuscule, minuscule, chiffre, caractere special';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline_rounded,
                controller: _confirm,
                obscureText: true,
                validator: (v) {
                  if (v != _password.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Reinitialiser',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}