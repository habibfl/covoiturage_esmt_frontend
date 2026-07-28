import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/error_utils.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class PublishTripScreen extends StatefulWidget {
  const PublishTripScreen({super.key});

  @override
  State<PublishTripScreen> createState() => _PublishTripScreenState();
}

class _PublishTripScreenState extends State<PublishTripScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _price = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_date == null ||
        _time == null ||
        _from.text.isEmpty ||
        _to.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dateStr =
        '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    final result = await TripService.publierTrajet({
      'pointDepart': _from.text.trim(),
      'pointArrivee': _to.text.trim(),
      'dateDepart': dateStr,
      'heureDepart': timeStr,
      'nbPlacesDisponibles': _seats,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet publie avec succes')),
      );
      context.go('/home');
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Impossible de publier le trajet.',
        isAuthError: result.isAuthError,
      );
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || d == null) return;
    setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || t == null) return;
    setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publier un trajet'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(CupertinoIcons.back, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [AppShadows.soft],
            ),
            child: Column(
              children: [
                CustomInput(
                  label: 'Point de depart',
                  icon: CupertinoIcons.location,
                  controller: _from,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  label: 'Destination',
                  icon: CupertinoIcons.flag,
                  controller: _to,
                ),
                const SizedBox(height: 16),
                _PickerRow(
                  icon: CupertinoIcons.calendar,
                  label: _date == null
                      ? 'Choisir une date'
                      : '${_date!.day}/${_date!.month}/${_date!.year}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                _PickerRow(
                  icon: CupertinoIcons.time,
                  label: _time == null
                      ? 'Choisir une heure'
                      : _time!.format(context),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 24),
                _SeatSlider(
                  seats: _seats,
                  onChanged: (value) => setState(() => _seats = value),
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Prix optionnel',
                  icon: CupertinoIcons.money_dollar,
                  controller: _price,
                  keyboardType: TextInputType.number,
                  hint: 'Montant en FCFA',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Publier le trajet',
            loading: _isLoading,
            onPressed: _publish,
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatSlider extends StatelessWidget {
  final int seats;
  final ValueChanged<int> onChanged;

  const _SeatSlider({required this.seats, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Places disponibles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$seats',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primarySoft,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.08),
          ),
          child: Slider(
            value: seats.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }
}