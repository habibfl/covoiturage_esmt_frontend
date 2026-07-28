import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/error_utils.dart';
import '../services/firebase_service.dart';
import '../services/location_tracking_service.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_slide_in.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _trips = [];
  String? _busyTripId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (LocationTrackingService.isTracking) {
      LocationTrackingService.stopTracking();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = await AuthService.getUserId();
    if (!mounted) return;
    final trips = userId == null
        ? <Map<String, dynamic>>[]
        : await TripService.getTrajetsByConducteur(userId);
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  Future<void> _start(Map<String, dynamic> trip) async {
    final tripId = trip['id']?.toString();
    if (tripId == null) return;
    setState(() => _busyTripId = tripId);

    final started = await LocationTrackingService.startTracking(tripId);
    if (!mounted) return;

    if (!started) {
      setState(() => _busyTripId = null);
      showErrorSnackBar(
        context,
        'Impossible d\'activer le suivi GPS : autorisez la geolocalisation dans les parametres de votre navigateur.',
      );
      return;
    }

    final result = await TripService.updateTripStatus(tripId, 'EN_COURS');
    if (!mounted) return;

    if (!result.success) {
      await LocationTrackingService.stopTracking();
      if (!mounted) return;
      setState(() => _busyTripId = null);
      showErrorSnackBar(
        context,
        result.message ?? 'Impossible de demarrer le trajet cote serveur.',
        isAuthError: result.isAuthError,
      );
      return;
    }

    setState(() => _busyTripId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suivi GPS actif')),
    );
    await _load();
  }

  Future<void> _finish(Map<String, dynamic> trip) async {
    final tripId = trip['id']?.toString();
    if (tripId == null) return;
    setState(() => _busyTripId = tripId);

    await LocationTrackingService.stopTracking();
    if (!mounted) return;

    final result = await TripService.updateTripStatus(tripId, 'TERMINE');
    if (!mounted) return;

    if (result.success) {
      await FirebaseService.clearLocation(tripId);
      if (!mounted) return;
    }

    setState(() => _busyTripId = null);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet termine')),
      );
      await _load();
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Impossible de terminer le trajet.',
        isAuthError: result.isAuthError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes trajets'),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(CupertinoIcons.back, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _trips.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.car_detailed,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Vous n'avez publie aucun trajet",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      final tripId = trip['id']?.toString();
                      final busy = _busyTripId == tripId;
                      return FadeSlideIn(
                        index: index,
                        child: _TripCard(
                          trip: trip,
                          busy: busy,
                          onStart: () => _start(trip),
                          onFinish: () => _finish(trip),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  const _TripCard({
    required this.trip,
    required this.busy,
    required this.onStart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final departure = trip['departure']?.toString() ?? 'Depart';
    final arrival = trip['arrival']?.toString() ?? 'Arrivee';
    final time = trip['time']?.toString() ?? '--:--';
    final statut = trip['statut']?.toString() ?? 'PLANIFIE';

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
                child: Text(
                  '$departure -> $arrival',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _StatusBadge(statut: statut),
            ],
          ),
          const SizedBox(height: 6),
          Text(time, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          if (statut == 'PLANIFIE')
            CustomButton(
              label: 'Demarrer le trajet',
              loading: busy,
              onPressed: onStart,
            )
          else if (statut == 'EN_COURS') ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suivi GPS actif',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Terminer le trajet',
              secondary: true,
              backgroundColor: AppColors.statusRed,
              loading: busy,
              onPressed: onFinish,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statut;

  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (statut) {
      case 'EN_COURS':
        color = AppColors.accentGreen;
        label = 'En cours';
        break;
      case 'TERMINE':
        color = AppColors.textSecondary;
        label = 'Termine';
        break;
      case 'ANNULE':
        color = AppColors.statusRed;
        label = 'Annule';
        break;
      default:
        color = AppColors.statusOrange;
        label = 'Planifie';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}