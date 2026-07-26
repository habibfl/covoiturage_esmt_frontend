import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../services/vehicle_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDark = false;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = 'passenger';
  String _photoUrl = '';
  bool _hasVehicle = false;
  int _pendingRequests = 0;
  Uint8List? _pickedPhotoBytes;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _isDark = AppColors.isDark;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final firstName = await AuthService.getFirstName();
    final lastName = await AuthService.getLastName();
    final email = await AuthService.getEmail();
    final role = await AuthService.getRole();
    final photoUrl = await AuthService.getProfilePhotoUrl();
    final hasVehicle = await VehicleService.hasVehicle();
    if (!mounted) return;
    setState(() {
      _firstName = firstName;
      _lastName = lastName;
      _email = email;
      _role = role;
      _photoUrl = photoUrl;
      _hasVehicle = hasVehicle;
    });

    if (hasVehicle) {
      final count = await ReservationService.countPendingForDriver();
      if (!mounted) return;
      setState(() => _pendingRequests = count);
    }
  }

  Future<void> _toggleTheme(bool value) async {
    AppColors.setDark(value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    setState(() => _isDark = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedPhotoBytes = bytes;
      _uploadingPhoto = true;
    });
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      await AuthService.saveProfilePhotoUrl(url);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        'Upload impossible pour le moment, photo affichee localement',
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = ('$_firstName $_lastName').trim();
    final displayName = fullName.isEmpty ? 'Mon profil' : fullName;
    final displayEmail = _email.isEmpty ? 'Aucun email enregistre' : _email;
    final initial = _firstName.isEmpty ? '?' : _firstName[0].toUpperCase();
    final isDriver = _role == 'driver' || _hasVehicle;
    final roleLabel = isDriver ? 'Conducteur' : 'Passager';
    final badgeBg = isDriver ? AppColors.accentSoft : AppColors.primarySoft;
    final badgeText = isDriver ? AppColors.accent : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(CupertinoIcons.back, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              fixedSize: const Size(40, 40),
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: _ProfileAvatar(
                        initial: initial,
                        photoUrl: _photoUrl,
                        localBytes: _pickedPhotoBytes,
                        uploading: _uploadingPhoto,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(displayEmail, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    roleLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                  ),
                ),
                if (isDriver) ...[
                  const SizedBox(height: 16),
                  const _DriverStatsCard(
                    tripsPublished: 0,
                    averageRating: 0,
                    seatsOffered: 0,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                _SectionLabel('Activite'),
_SettingsGroup(
  rows: [
    if (isDriver) ...[
      _SettingsRow(
        icon: CupertinoIcons.car_detailed,
        color: AppColors.accent,
        label: 'Mes trajets',
        onTap: () => context.go('/my-trips'),
      ),
      _SettingsRow(
        icon: CupertinoIcons.tray_full,
        color: AppColors.primary,
        label: 'Demandes de reservation',
        onTap: () => context.go('/trip-requests'),
        trailing: _pendingRequests > 0
            ? _CountBadge(count: _pendingRequests)
            : null,
      ),
    ],
    _SettingsRow(
      icon: CupertinoIcons.clock,
      color: AppColors.statusOrange,
      label: 'Historique des trajets',
      onTap: () => context.go('/trip-history'),
    ),
  ],
),
                const SizedBox(height: 20),
                _SectionLabel('Preferences'),
                _SettingsGroup(
                  rows: [
                    _SettingsRow(
                      icon: CupertinoIcons.moon,
                      color: AppColors.primary,
                      label: 'Mode sombre',
                      trailing: Switch(
                        value: _isDark,
                        onChanged: _toggleTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.statusRedSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Deconnexion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusRed,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusRed,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onColor,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initial;
  final String photoUrl;
  final Uint8List? localBytes;
  final bool uploading;

  const _ProfileAvatar({
    required this.initial,
    required this.photoUrl,
    required this.localBytes,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (localBytes != null) {
      content = ClipOval(
        child: Image.memory(
          localBytes!,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        ),
      );
    } else if (photoUrl.isNotEmpty) {
      content = ClipOval(
        child: Image.network(
          photoUrl,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        ),
      );
    } else {
      content = Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.onColor,
          ),
        ),
      );
    }

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          content,
          if (uploading)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: CupertinoActivityIndicator(color: AppColors.onColor),
            ),
        ],
      ),
    );
  }
}

class _DriverStatsCard extends StatelessWidget {
  final int tripsPublished;
  final double averageRating;
  final int seatsOffered;

  const _DriverStatsCard({
    required this.tripsPublished,
    required this.averageRating,
    required this.seatsOffered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.soft],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'Trajets publies',
              value: '$tripsPublished',
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _StatCell(
              label: 'Note moyenne',
              value: averageRating.toStringAsFixed(1),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _StatCell(
              label: 'Places offertes',
              value: '$seatsOffered',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsRow> rows;

  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.soft],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(color: AppColors.divider, height: 1, indent: 68),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}