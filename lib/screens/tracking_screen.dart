import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/colors.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../services/trip_service.dart';
import '../widgets/address_timeline_tile.dart';
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
  bool _cancelling = false;
  Map<String, dynamic>? _trip;
  String? _reservationId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    String? tripId = widget.tripId;
    String? reservationId = widget.reservationId;

    if (tripId == null) {
      final active = await ReservationService.getActiveReservation();
      if (active != null) {
        reservationId = active['id']?.toString();
        tripId = active['trajetId']?.toString();
      }
    }

    Map<String, dynamic>? trip;
    if (tripId != null) {
      trip = await TripService.getTrajetById(tripId);
    }

    if (!mounted) return;
    setState(() {
      _trip = trip;
      _reservationId = reservationId;
      _loading = false;
    });
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
    if (confirm != true) return;

    if (_reservationId == null) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Aucune reservation a annuler.');
      return;
    }

    setState(() => _cancelling = true);
    final result = await ReservationService.cancelReservation(_reservationId!);
    if (!mounted) return;
    setState(() => _cancelling = false);

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

    final trip = _trip!;
    final departure = trip['departure']?.toString() ?? 'Depart';
    final arrival = trip['arrival']?.toString() ?? 'Arrivee';
    final driverName = trip['driverName']?.toString() ?? '';
    final vehicle = trip['vehicle']?.toString() ?? '';
    final latDepart = _toDouble(trip['latDepart']);
    final lngDepart = _toDouble(trip['lngDepart']);
    final latArrivee = _toDouble(trip['latArrivee']);
    final lngArrivee = _toDouble(trip['lngArrivee']);
    final hasCoordinates = latDepart != null &&
        lngDepart != null &&
        latArrivee != null &&
        lngArrivee != null;

    return Scaffold(
      body: Stack(
        children: [
          if (hasCoordinates)
            _TrackingMap(
              origin: LatLng(latDepart, lngDepart),
              destination: LatLng(latArrivee, lngArrivee),
            )
          else
            const _MapFallback(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => context.go('/home'),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [AppShadows.soft],
                ),
                child: Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 64,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [AppShadows.soft],
              ),
              child: AddressTimelineTile(
                departure: departure,
                arrival: arrival,
                compact: true,
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.2,
            maxChildSize: 0.85,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [AppShadows.soft],
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (driverName.isNotEmpty)
                      DriverProfileCard(
                        name: driverName,
                        vehicle: vehicle,
                        rating: _toDouble(trip['rating']) ?? 0,
                        compact: true,
                      )
                    else
                      Text(
                        'Conducteur non renseigne',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Annuler',
                            secondary: true,
                            icon: CupertinoIcons.xmark,
                            loading: _cancelling,
                            onPressed: _confirmCancel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  final LatLng origin;
  final LatLng destination;

  const _TrackingMap({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: origin, zoom: 14),
      padding: EdgeInsets.zero,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [origin, destination],
          color: AppColors.primary,
          width: 5,
        ),
      },
      markers: {
        Marker(markerId: const MarkerId('origin'), position: origin),
        Marker(markerId: const MarkerId('dest'), position: destination),
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback();

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
              'Position du trajet indisponible',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}