import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _immatriculation = TextEditingController();
  final _couleur = TextEditingController();
  final _places = TextEditingController();
  bool _loading = false;
  bool _checking = true;
  Map<String, dynamic>? _existingVehicle;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final vehicle = await VehicleService.getMyVehicle();
    if (!mounted) return;
    setState(() {
      _existingVehicle = vehicle;
      _checking = false;
    });
  }

  @override
  void dispose() {
    _marque.dispose();
    _modele.dispose();
    _immatriculation.dispose();
    _couleur.dispose();
    _places.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await VehicleService.addVehicle(
      marque: _marque.text.trim(),
      modele: _modele.text.trim(),
      immatriculation: _immatriculation.text.trim(),
      couleur: _couleur.text.trim(),
      nombrePlacesTotales: int.tryParse(_places.text.trim()) ?? 0,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      await AuthService.setRole('driver');
      if (!mounted) return;
      context.go('/profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? "Impossible d'enregistrer le vehicule"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_existingVehicle != null) {
      return _ExistingVehicleView(vehicle: _existingVehicle!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajouter un vehicule'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/profile'),
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
                label: 'Marque',
                icon: Icons.directions_car_outlined,
                controller: _marque,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Modele',
                icon: Icons.time_to_leave_outlined,
                controller: _modele,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Immatriculation',
                icon: Icons.confirmation_number_outlined,
                controller: _immatriculation,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Couleur',
                icon: Icons.palette_outlined,
                controller: _couleur,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Nombre de places totales',
                icon: Icons.event_seat_outlined,
                controller: _places,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Nombre invalide';
                  if (n < 1) return 'Doit etre superieur a 0';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Enregistrer mon vehicule',
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

class _ExistingVehicleView extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _ExistingVehicleView({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final marque = vehicle['marque']?.toString() ?? '—';
    final modele = vehicle['modele']?.toString() ?? '—';
    final matricule = vehicle['matricule']?.toString() ?? '—';
    final couleur = vehicle['couleur']?.toString() ?? '—';
    final nbPlaces = vehicle['nbPlaces']?.toString() ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon vehicule'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppShadows.soft],
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.directions_car_outlined, label: 'Marque', value: marque),
                Divider(color: AppColors.divider, height: 1, indent: 60),
                _InfoRow(icon: Icons.time_to_leave_outlined, label: 'Modele', value: modele),
                Divider(color: AppColors.divider, height: 1, indent: 60),
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Immatriculation',
                  value: matricule,
                ),
                Divider(color: AppColors.divider, height: 1, indent: 60),
                _InfoRow(icon: Icons.palette_outlined, label: 'Couleur', value: couleur),
                Divider(color: AppColors.divider, height: 1, indent: 60),
                _InfoRow(
                  icon: Icons.event_seat_outlined,
                  label: 'Places',
                  value: nbPlaces,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}