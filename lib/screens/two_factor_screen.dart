import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../widgets/custom_button.dart';

class TwoFactorScreen extends StatefulWidget {
  final String email;

  const TwoFactorScreen({super.key, required this.email});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const int _length = 6;
  final List<TextEditingController> _controllers = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _length; i++) {
        final sourceIndex = index + i;
        if (sourceIndex < digits.length) {
          _controllers[i < _controllers.length ? i : _length - 1].text = '';
        }
      }
      for (int i = 0; i < digits.length && i < _length; i++) {
        _controllers[i].text = digits[i];
      }
      final lastFilled = digits.length.clamp(0, _length) - 1;
      if (lastFilled >= 0 && lastFilled < _length - 1) {
        _focusNodes[lastFilled + 1].requestFocus();
      } else if (lastFilled == _length - 1) {
        _focusNodes[lastFilled].unfocus();
        _submit();
      }
      return;
    }

    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (value.isNotEmpty && index == _length - 1) {
      _submit();
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

 Future<void> _submit() async {
  final code = _code;
  if (code.length != _length || _loading) return;
  setState(() => _loading = true);
  final result = await AuthService.verifyTwoFactor(widget.email, code);
  if (!mounted) return;
  setState(() => _loading = false);

  if (result.success) {
    final isAdmin = await AuthService.isAdmin();
    if (!mounted) return;
    context.go(isAdmin ? '/admin' : '/home');
  } else {
    showErrorSnackBar(
      context,
      result.message ?? 'Code invalide',
      isAuthError: result.isAuthError,
    );
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }
}

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification'),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Text(
                  'Code de verification',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code envoye a ${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_length, (index) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: _length,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.inputFill,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onChanged(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Verifier',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}