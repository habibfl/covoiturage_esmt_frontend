import 'dart:async';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/avis_service.dart';
import '../services/error_utils.dart';
import '../services/firebase_service.dart';
import '../services/location_tracking_service.dart';
import '../services/reservation_service.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/driver_profile_card.dart';

class TrackingScreen extends StatefulWidget {
  final String? tripId;
  final String? reservationId;

  const TrackingScreen({super.key, this.tripId, this.reservationId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _loading = true;
  bool _isDriver = false;
  bool _busy = false;

  Map<String, dynamic>? _trip;
  String? _tripId;
  String? _reservationId;
  String? _status;
  double _driverRating = 0;

  GoogleMapController? _mapController;
  StreamSubscription<DatabaseEvent>? _locationSub;
  LatLng? _livePosition;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    final role = await AuthService.getRole();
    if (!mounted) return;
    final isDriver = role == 'driver';

    Map<String, dynamic>? trip;
    String? tripId;
    String? reservationId;
    String? status;

    if (isDriver) {
      final userId = await AuthService.getUserId();
      if (!mounted) return;
      if (userId != null) {
        final trips = await TripService.getTrajetsByConducteur(userId);
        if (!mounted) return;
        Map<String, dynamic>? current;
        for (final t in trips) {
          if (t['statut'] == 'EN_COURS') {
            current = t;
            break;
          }
        }
        current ??= trips.firstWhere(
          (t) => t['statut'] == 'PLANIFIE',
          orElse: () => {},
        );
        if (current.isNotEmpty) {
          tripId = current['id']?.toString();
          trip = await TripService.getTrajetById(tripId!);
          if (!mounted) return;
        }
      }
    } else {
      tripId = widget.tripId;
      reservationId = widget.reservationId;

      final active = await ReservationService.getActiveReservation();
      if (!mounted) return;
      if (tripId == null) {
        if (active != null) {
          reservationId = active['id']?.toString();
          tripId = active['trajetId']?.toString();
          status = active['statutReservation']?.toString();
        }
      } else if (active != null && active['id']?.toString() == reservationId) {
        status = active['statutReservation']?.toString();
      }

      if (tripId != null) {
        trip = await TripService.getTrajetById(tripId);
        if (!mounted) return;
      }
      if (status != null && reservationId != null) {
        await ReservationService.setLastSeenStatus(reservationId, status);
        if (!mounted) return;
      }
    }

    double driverRating = 0;
    if (!isDriver && trip != null && trip['conducteurId'] != null) {
      driverRating =
          await AvisService.getNoteMoyenne(trip['conducteurId'].toString());
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() {
      _isDriver = isDriver;
      _trip = trip;
      _tripId = tripId;
      _reservationId = reservationId;
      _status = status;
      _driverRating = driverRating;
      _loading = false;
    });

    if (tripId != null) {
      _listenToLocation(tripId);
    }
  }

  Future<void> _refreshStatus() async {
    if (_isDriver) {
      await _init();
      return;
    }
    final active = await ReservationService.getActiveReservation();
    if (!mounted) return;
    if (active != null && active['id']?.toString() == _reservationId) {
      setState(() => _status = active['statutReservation']?.toString());
    }
  }

  void _listenToLocation(String tripId) {
    _locationSub?.cancel();
    _locationSub = FirebaseService.listenLocation(tripId).listen((event) {
      final data = event.snapshot.value;
      if (data is! Map) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final position = LatLng(lat, lng);
      if (!mounted) return;
      setState(() => _livePosition = position);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(position));
      }
    });
  }

  Future<void> _startTrip() async {
    final tripId = _tripId;
    if (tripId == null) return;
    setState(() => _busy = true);

    final started = await LocationTrackingService.startTracking(tripId);
    if (!mounted) return;

    if (!started) {
      setState(() => _busy = false);
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
      setState(() => _busy = false);
      showErrorSnackBar(
        context,
        result.message ?? 'Impossible de demarrer le trajet.',
        isAuthError: result.isAuthError,
      );
      return;
    }

    setState(() => _busy = false);
    await _init();
  }

  Future<void> _finishTrip() async {
    final tripId = _tripId;
    if (tripId == null) return;
    setState(() => _busy = true);

    await LocationTrackingService.stopTracking();
    if (!mounted) return;

    final result = await TripService.updateTripStatus(tripId, 'TERMINE');
    if (!mounted) return;

    if (result.success) {
      await FirebaseService.clearLocation(tripId);
      if (!mounted) return;
    }
    setState(() => _busy = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet termine')),
      );
      context.go('/home');
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Impossible de terminer le trajet.',
        isAuthError: result.isAuthError,
      );
    }
  }

  Future<void> _confirmCancel() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Annuler le trajet'),
        content: const Text('Voulez-vous vraiment annuler ce trajet ?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm != true) return;

    if (_reservationId == null) {
      showErrorSnackBar(context, 'Aucune reservation a annuler.');
      return;
    }

    setState(() => _busy = true);
    final result = await ReservationService.cancelReservation(_reservationId!);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation annulee')),
      );
      context.go('/home');
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Annulation impossible',
        isAuthError: result.isAuthError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(
            color: AppColors.primary,
            radius: 14,
          ),
        ),
      );
    }

    if (_trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.map, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Aucun trajet en cours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Vous n'avez pas de trajet actif a suivre pour le moment.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: "Retour a l'accueil",
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _isDriver ? _buildDriverView(context) : _buildPassengerView(context);
  }

  // vue conducteur
  Widget _buildDriverView(BuildContext context) {
    final trip = _trip!;
    final departure = trip['departure']?.toString() ?? 'Depart';
    final arrival = trip['arrival']?.toString() ?? 'Arrivee';
    final statut = trip['statut']?.toString() ?? 'PLANIFIE';
    final isRunning = statut == 'EN_COURS';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: (isRunning && _livePosition != null)
                ? _LiveMap(
                    position: _livePosition!,
                    onMapCreated: (controller) => _mapController = controller,
                  )
                : _MapFallback(
                    text: isRunning
                        ? 'Activation du suivi GPS en cours...'
                        : 'Trajet pas encore demarre',
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _FloatingTopRow(
                onBack: () => context.go('/home'),
                onRefresh: _refreshStatus,
                compactLabel: '$departure -> $arrival',
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _BottomSheetPanel(
                child: Row(
                  children: [
                    Icon(
                      isRunning
                          ? CupertinoIcons.location_solid
                          : CupertinoIcons.location,
                      size: 18,
                      color: isRunning
                          ? AppColors.accentGreen
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isRunning
                            ? 'Position partagee avec le(s) passager(s)'
                            : 'Pret a demarrer',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: CustomButton(
                        label: isRunning ? 'Terminer' : 'Demarrer',
                        backgroundColor:
                            isRunning ? AppColors.statusRed : null,
                        loading: _busy,
                        onPressed: isRunning ? _finishTrip : _startTrip,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // vue passager
  Widget _buildPassengerView(BuildContext context) {
    final trip = _trip!;
    final departure = trip['departure']?.toString() ?? 'Depart';
    final arrival = trip['arrival']?.toString() ?? 'Arrivee';
    final driverName = trip['driverName']?.toString() ?? '';
    final vehicle = trip['vehicle']?.toString() ?? '';
    final isRejected = _status == 'REJETEE';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _livePosition != null
                ? _LiveMap(
                    position: _livePosition!,
                    onMapCreated: (controller) => _mapController = controller,
                  )
                : const _MapFallback(
                    text:
                        'En attente du demarrage du trajet par le conducteur',
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _FloatingTopRow(
                onBack: () => context.go('/home'),
                onRefresh: _refreshStatus,
                compactLabel: '$departure -> $arrival',
                statusChip: _StatusChip(status: _status),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _BottomSheetPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (driverName.isNotEmpty)
                      DriverProfileCard(
                        name: driverName,
                        vehicle: vehicle,
                        rating: _driverRating,
                        compact: true,
                      )
                    else
                      Text(
                        'Conducteur non renseigne',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 10),
                    if (isRejected)
                      CustomButton(
                        label: 'Rechercher un autre trajet',
                        onPressed: () => context.go('/search'),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'Contact',
                              secondary: true,
                              icon: CupertinoIcons.phone,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              label: 'Annuler',
                              secondary: true,
                              icon: CupertinoIcons.xmark,
                              loading: _busy,
                              onPressed: _confirmCancel,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// widgets compacts, reutilises dans les deux vues

class _FloatingTopRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final String compactLabel;
  final Widget? statusChip;

  const _FloatingTopRow({
    required this.onBack,
    required this.onRefresh,
    required this.compactLabel,
    this.statusChip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: CupertinoIcons.back, onTap: onBack),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppShadows.soft],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          compactLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (statusChip != null) ...[
                        const SizedBox(width: 8),
                        statusChip!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(icon: CupertinoIcons.refresh, onTap: onRefresh),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [AppShadows.soft],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    late Color color;
    late String text;

    switch (status) {
      case 'EN_ATTENTE':
        color = AppColors.statusOrange;
        text = 'En attente';
        break;
      case 'CONFIRMEE':
        color = AppColors.accentGreen;
        text = 'Confirmee';
        break;
      case 'REJETEE':
        color = AppColors.statusRed;
        text = 'Refusee';
        break;
      default:
        return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          text,
          key: ValueKey(text),
          style: TextStyle(
            color: AppColors.onColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetPanel extends StatelessWidget {
  final Widget child;

  const _BottomSheetPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.75),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveMap extends StatelessWidget {
  final LatLng position;
  final ValueChanged<GoogleMapController> onMapCreated;

  const _LiveMap({required this.position, required this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: position, zoom: 15),
      onMapCreated: onMapCreated,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('driver'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  final String text;

  const _MapFallback({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.map, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}