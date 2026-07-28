import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await AdminService.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id == null) return;
    final isBlocked = user['statutCompte'] == false;
    final action = isBlocked ? 'debloquer' : 'bloquer';
    final name = ('${user['prenom'] ?? ''} ${user['nom'] ?? ''}').trim();

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isBlocked ? 'Debloquer le compte' : 'Bloquer le compte'),
        content: Text(
          'Voulez-vous vraiment $action le compte de ${name.isEmpty ? 'cet utilisateur' : name} ?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !isBlocked,
            onPressed: () => Navigator.pop(context, true),
            child: Text(isBlocked ? 'Debloquer' : 'Bloquer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _processing.add(id));
    final result = isBlocked
        ? await AdminService.unblockUser(id)
        : await AdminService.blockUser(id);
    if (!mounted) return;
    setState(() => _processing.remove(id));

    if (result.success) {
      setState(() {
        final index = _users.indexWhere((u) => u['id']?.toString() == id);
        if (index != -1) {
          _users[index] = {..._users[index], 'statutCompte': isBlocked};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked ? 'Compte debloque' : 'Compte bloque',
          ),
        ),
      );
    } else {
      showErrorSnackBar(
        context,
        result.message ?? "Impossible d'effectuer cette action",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _users.length;
    final blocked = _users.where((u) => u['statutCompte'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(CupertinoIcons.square_arrow_right, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.statusRedSoft,
                foregroundColor: AppColors.statusRed,
                fixedSize: const Size(40, 40),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _StatsCard(total: total, blocked: blocked),
                  const SizedBox(height: 20),
                  Text(
                    'Utilisateurs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.person_2,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun utilisateur trouve',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._users.map((user) {
                      final id = user['id']?.toString() ?? '';
                      return _UserTile(
                        user: user,
                        processing: _processing.contains(id),
                        onToggle: () => _toggleBlock(user),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int total;
  final int blocked;

  const _StatsCard({required this.total, required this.blocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(label: 'Utilisateurs', value: '$total'),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _StatCell(
              label: 'Comptes bloques',
              value: '$blocked',
              valueColor: blocked > 0 ? AppColors.statusRed : null,
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
  final Color? valueColor;

  const _StatCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool processing;
  final VoidCallback onToggle;

  const _UserTile({
    required this.user,
    required this.processing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = ('${user['prenom'] ?? ''} ${user['nom'] ?? ''}').trim();
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'ROLE_USER';
    final isActive = user['statutCompte'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Utilisateur' : fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _StatusPill(isActive: isActive),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                width: 110,
                child: OutlinedButton(
                  onPressed: processing ? null : onToggle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isActive ? AppColors.statusRed : AppColors.accentGreen,
                    side: BorderSide(
                      color:
                          isActive ? AppColors.statusRed : AppColors.accentGreen,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: processing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isActive
                                ? AppColors.statusRed
                                : AppColors.accentGreen,
                          ),
                        )
                      : Text(
                          isActive ? 'Bloquer' : 'Debloquer',
                          style: const TextStyle(fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accentGreen : AppColors.statusRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Actif' : 'Bloque',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}