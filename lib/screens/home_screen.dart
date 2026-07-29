import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/trip_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _mode = 0;
  String _firstName = '';
  String _role = 'passenger';
  bool _roleLoaded = false;
  int _notificationCount = 0;
  late Future<TripsResult> _tripsFuture;

  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _selectedDate;
  int _passengers = 1;

  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tripsFuture = _fetchTrips();
    _loadUser();
  }

  Future<TripsResult> _fetchTrips() async {
    final result = await TripService.getTrajetsWithStatus();
    final filtered = _bookableTrips(result);
    if (!mounted || result.success) return filtered;
    showErrorSnackBar(
      context,
      result.errorMessage ?? 'Impossible de charger les trajets.',
    );
    return filtered;
  }

  TripsResult _bookableTrips(TripsResult result) {
    return TripsResult(
      trips: result.trips
          .where((t) => t['statut'] == 'PLANIFIE' || t['statut'] == 'EN_COURS')
          .toList(),
      success: result.success,
      errorMessage: result.errorMessage,
    );
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final name = await AuthService.getFirstName();
    final role = await AuthService.getRole();
    if (!mounted) return;
    setState(() {
      _firstName = name;
      _role = role;
      if (!_roleLoaded) {
        _mode = role == 'driver' ? 1 : 0;
        _roleLoaded = true;
      }
    });

    final count = await _computeNotificationCount(role);
    if (!mounted) return;
    setState(() => _notificationCount = count);
  }

  Future<int> _computeNotificationCount(String role) async {
    if (role == 'driver') {
      return ReservationService.countPendingForDriver();
    }
    final active = await ReservationService.getActiveReservation();
    if (active == null) return 0;
    final status = active['statutReservation']?.toString();
    final id = active['id']?.toString();
    if (status == null || id == null) return 0;
    if (status != 'CONFIRMEE' && status != 'REJETEE') return 0;
    final lastSeen = await ReservationService.getLastSeenStatus(id);
    return lastSeen == status ? 0 : 1;
  }

  void _swap() {
    final tmp = _from.text;
    setState(() {
      _from.text = _to.text;
      _to.text = tmp;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  void _goTab(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/tracking');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Future<void> _goBrandTarget() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    context.go(loggedIn ? '/home' : '/login');
  }

  Future<void> _showNotifications() async {
    final role = _role;
    List<_NotificationItem> items = [];

    if (role == 'driver') {
      final requests = await ReservationService.getPendingRequests();
      items = requests.map((r) {
        final passager = r['passager']?.toString() ?? 'Un passager';
        final departure = r['departure']?.toString() ?? '';
        final arrival = r['arrival']?.toString() ?? '';
        return _NotificationItem(
          title: 'Nouvelle demande de reservation',
          subtitle: '$passager - $departure -> $arrival',
          route: '/trip-requests',
        );
      }).toList();
    } else {
      final active = await ReservationService.getActiveReservation();
      if (active != null) {
        final status = active['statutReservation']?.toString();
        final id = active['id']?.toString();
        if (status == 'CONFIRMEE' || status == 'REJETEE') {
          items.add(
            _NotificationItem(
              title: status == 'CONFIRMEE'
                  ? 'Reservation confirmee'
                  : 'Reservation refusee',
              subtitle: 'Voir les details de votre trajet',
              route: '/tracking',
            ),
          );
          if (id != null) {
            await ReservationService.setLastSeenStatus(id, status!);
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _notificationCount = 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune notification pour le moment',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),
              for (final item in items)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.route);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.bell_fill,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _firstName.isEmpty ? 'Etudiant ESMT' : _firstName;
    final initial = _firstName.isEmpty ? 'E' : _firstName[0].toUpperCase();
    final isDriver = _role == 'driver';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              displayName: displayName,
              initial: initial,
              isDriver: isDriver,
              notificationCount: _notificationCount,
              onProfile: () => context.go('/profile'),
              onNotifications: _showNotifications,
              onBrandTap: _goBrandTarget,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (isDriver) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentButton(
                              label: 'Trouver un trajet',
                              selected: _mode == 0,
                              onTap: () => setState(() => _mode = 0),
                            ),
                          ),
                          Expanded(
                            child: _SegmentButton(
                              label: 'Publier un trajet',
                              selected: _mode == 1,
                              onTap: () => setState(() => _mode = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_mode == 0 || !isDriver) ...[
                    _SearchCard(
                      from: _from,
                      to: _to,
                      onSwap: _swap,
                      selectedDate: _selectedDate,
                      onPickDate: _pickDate,
                      passengers: _passengers,
                      onDecrease: _passengers > 1
                          ? () => setState(() => _passengers--)
                          : null,
                      onIncrease: _passengers < 6
                          ? () => setState(() => _passengers++)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Rechercher',
                      onPressed: () => context.go('/search'),
                    ),
                    if (!isDriver) ...[
                      const SizedBox(height: 16),
                      _BecomeDriverCta(
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                    if (_recentSearches.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Recherches recentes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppShadows.soft],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _recentSearches.length; i++) ...[
                              _RecentSearchTile(text: _recentSearches[i]),
                              if (i != _recentSearches.length - 1)
                                Divider(
                                  color: AppColors.divider,
                                  height: 1,
                                  indent: 52,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    _PublishShortcutCard(
                      onPublish: () => context.go('/publish'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'Trajets disponibles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<TripsResult>(
                    future: _tripsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final trips = snapshot.data?.trips ?? [];
                      if (trips.isEmpty) return const _EmptyTrips();
                      return Column(
                        children: trips
                            .asMap()
                            .entries
                            .map(
                              (entry) => FadeSlideIn(
                                index: entry.key,
                                child: TripCard(
                                  trip: entry.value,
                                  onReserve: () => context.go(
                                    '/booking',
                                    extra: entry.value,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: _goTab,
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String subtitle;
  final String route;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _Header extends StatelessWidget {
  final String displayName;
  final String initial;
  final bool isDriver;
  final int notificationCount;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onBrandTap;

  const _Header({
    required this.displayName,
    required this.initial,
    required this.isDriver,
    required this.notificationCount,
    required this.onProfile,
    required this.onNotifications,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBrandTap,
            child: Image.asset(
              'assets/images/esmt1.png',
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isDriver
                          ? CupertinoIcons.car_detailed
                          : CupertinoIcons.person,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onNotifications,
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.bell,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.statusRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$notificationCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BecomeDriverCta extends StatelessWidget {
  final VoidCallback onTap;

  const _BecomeDriverCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.add_circled,
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajouter un vehicule pour publier un trajet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onColor : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController from;
  final TextEditingController to;
  final VoidCallback onSwap;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final int passengers;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _SearchCard({
    required this.from,
    required this.to,
    required this.onSwap,
    required this.selectedDate,
    required this.onPickDate,
    required this.passengers,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [AppShadows.soft],
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  _PlainField(
                    controller: from,
                    hint: 'Point de depart',
                    icon: CupertinoIcons.circle,
                  ),
                  Divider(color: AppColors.divider, height: 1),
                  _PlainField(
                    controller: to,
                    hint: 'Destination',
                    icon: CupertinoIcons.location_solid,
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: InkWell(
                  onTap: onSwap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      size: 16,
                      color: AppColors.onColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppShadows.soft],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Demain'
                              : '${selectedDate!.day}/${selectedDate!.month}',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [AppShadows.soft],
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.person,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$passengers',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    InkWell(
                      onTap: onDecrease,
                      child: Icon(
                        CupertinoIcons.minus_circle,
                        size: 20,
                        color: onDecrease == null
                            ? AppColors.divider
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onIncrease,
                      child: Icon(
                        CupertinoIcons.plus_circle,
                        size: 20,
                        color: onIncrease == null
                            ? AppColors.divider
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlainField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _PlainField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
            decoration: InputDecoration(
              hintText: hint,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _PublishShortcutCard extends StatelessWidget {
  final VoidCallback onPublish;

  const _PublishShortcutCard({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.car_detailed, size: 32, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Vous avez de la place dans votre vehicule ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Publiez votre trajet et partagez les frais avec la communaute ESMT.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          CustomButton(label: 'Publier un trajet', onPressed: onPublish),
        ],
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final String text;

  const _RecentSearchTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(CupertinoIcons.clock, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              label: 'Recherche',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.location),
              activeIcon: Icon(CupertinoIcons.location_solid),
              label: 'Suivi',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.map, color: AppColors.primary, size: 30),
          const SizedBox(height: 12),
          Text(
            'Aucun trajet disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}