import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final result = await AuthService.login(
      email,
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go('/home');
    } else if (result.twoFactorRequired) {
      context.go('/verify-2fa', extra: email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? "Echec de l'authentification"),
        ),
      );
    }
  }

  Future<void> _goBrandTarget() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    context.go(loggedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 56;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _goBrandTarget,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/esmt1.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'CovoiturageESMT',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos trajets campus, simples et fiables.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 40),
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Connectez-vous avec votre adresse ESMT.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInput(
                        label: 'Email institutionnel',
                        hint: 'prenom.nom@esmt.sn',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email requis';
                          if (!v.trim().endsWith('@esmt.sn')) {
                            return 'Utilisez une adresse @esmt.sn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Mot de passe',
                        hint: 'Votre mot de passe',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? '6 caracteres minimum'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Mot de passe oublie ?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Se connecter',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      const TextSpan(text: 'Pas encore de compte ? '),
                      TextSpan(
                        text: "S'inscrire",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/register'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}