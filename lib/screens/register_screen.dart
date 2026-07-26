import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'passenger';
  bool _isLoading = false;
  PlatformFile? _studentCard;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _vehicle = TextEditingController();
  final _plate = TextEditingController();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _email.text.trim();
    final result = await AuthService.register({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': email,
      'password': _password.text.trim(),
      'phone': _phone.text.trim(),
      'role': _role,
      'studentCardName': _studentCard?.name,
    });
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.go('/home');
    } else if (result.twoFactorRequired) {
      context.go('/verify-2fa', extra: email);
    } else {
      showErrorSnackBar(
        context,
        result.message ?? "Echec de l'inscription",
        isAuthError: result.isAuthError,
      );
    }
  }

  Future<void> _pickStudentCard() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() => _studentCard = result.files.single);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _vehicle.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentCardUploaded = _studentCard != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Creer un compte'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              fixedSize: const Size(40, 40),
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          selected: _role == 'passenger',
                          icon: Icons.person_outline_rounded,
                          label: 'Passager',
                          onTap: () => setState(() => _role = 'passenger'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          selected: _role == 'driver',
                          icon: Icons.drive_eta_outlined,
                          label: 'Conducteur',
                          onTap: () => setState(() => _role = 'driver'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: 'Prenom',
                          icon: Icons.badge_outlined,
                          controller: _firstName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomInput(
                          label: 'Nom',
                          icon: Icons.person_outline_rounded,
                          controller: _lastName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: 'Email institutionnel',
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (!v.trim().endsWith('@esmt.sn')) {
                        return 'Utilisez une adresse @esmt.sn';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: 'Telephone',
                    icon: Icons.call_outlined,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: 'Mot de passe',
                    icon: Icons.lock_outline_rounded,
                    controller: _password,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? '6 caracteres minimum'
                        : null,
                  ),
                  if (_role == 'driver') ...[
                    const SizedBox(height: 16),
                    CustomInput(
                      label: 'Vehicule',
                      icon: Icons.directions_car_outlined,
                      controller: _vehicle,
                    ),
                    const SizedBox(height: 16),
                    CustomInput(
                      label: 'Plaque',
                      icon: Icons.confirmation_number_outlined,
                      controller: _plate,
                    ),
                  ],
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickStudentCard,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: studentCardUploaded
                            ? AppColors.accentSoft
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: studentCardUploaded
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          radius: 14,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Icon(
                                studentCardUploaded
                                    ? Icons.check_circle_rounded
                                    : Icons.upload_file_outlined,
                                color: studentCardUploaded
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                studentCardUploaded
                                    ? 'Carte etudiant ajoutee'
                                    : "Televerser la carte d'etudiant",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              if (studentCardUploaded)
                                TextButton(
                                  onPressed: _pickStudentCard,
                                  child: const Text('Changer'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: "S'inscrire",
                    loading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          const TextSpan(text: 'Deja un compte ? '),
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.go('/login'),
                          ),
                        ],
                      ),
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

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + 7);
        canvas.drawPath(extract, paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}