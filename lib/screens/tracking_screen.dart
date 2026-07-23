import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/colors.dart';
import '../services/error_utils.dart';
import '../services/firebase_service.dart';
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
  String? _status;

  GoogleMapController? _mapController;
  StreamSubscription<DatabaseEvent>? _locationSub;
  LatLng? _driverPosition;
  DateTime? _lastUpdate;

  static const Duration _freshnessWindow = Duration(minutes: 2);

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

    String? tripId = widget.tripId;
    String? reservationId = widget.reservationId;
    String? status;

    final active = await ReservationService.getActiveReservation();

    if (tripId == null) {
      if (active != null) {
        reservationId = active['id']?.toString();
        tripId = active['trajetId']?.toString();
        status = active['statutReservation']?.toString();
      }
    } else if (active != null && active['id']?.toString() == reservationId) {
      status = active['statutReservation']?.toString();
    }

    Map<String, dynamic>? trip;
    if (tripId != null) {
      trip = await TripService.getTrajetById(tripId);
    }

    if (status != null && reservationId != null) {
      await ReservationService.setLastSeenStatus(reservationId, status);
    }

    if (!mounted) return;
    setState(() {
      _trip = trip;
      _reservationId = reservationId;
      _status = status;
      _loading = false;
    });

    if (tripId != null) {
      _listenToLocation(tripId);
    }
  }

  void _listenToLocation(String tripId) {
    _locationSub?.cancel();
    _locationSub = FirebaseService.listenLocation(tripId).listen((event) {
      final data = event.snapshot.value;
      if (data is! Map) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      final ts = data['timestamp'];
      if (lat == null || lng == null) return;

      DateTime? updatedAt;
      if (ts is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      }

      if (!mounted) return;
      setState(() {
        _driverPosition = LatLng(lat, lng);
        _lastUpdate = updatedAt;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat, lng)),
        );
      }
    });
  }

  bool get _isPositionFresh {
    if (_driverPosition == null || _lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < _freshnessWindow;
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
    final isRejected = _status == 'REJETEE';

    return Scaffold(
      body: Stack(
        children: [
          _isPositionFresh
              ? _LiveMap(
                  position: _driverPosition!,
                  onMapCreated: (controller) => _mapController = controller,
                )
              : const _MapFallback(
                  text: 'En attente du demarrage du trajet par le conducteur',
                ),
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
            right: 16,
            child: InkWell(
              onTap: _init,
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
                  CupertinoIcons.refresh,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 64,
            right: 64,
            child: _StatusBanner(status: _status),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 110,
            left: 16,
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
                        rating: 0,
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

class _LiveMap extends StatelessWidget {
  final LatLng position;
  final ValueChanged<GoogleMapController> onMapCreated;

  const _LiveMap({required this.position, required this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: position, zoom: 15),
      onMapCreated: onMapCreated,
      padding: EdgeInsets.zero,
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

class _StatusBanner extends StatelessWidget {
  final String? status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    late Color color;
    late String text;

    switch (status) {
      case 'EN_ATTENTE':
        color = AppColors.statusOrange;
        text = 'En attente de confirmation du conducteur';
        break;
      case 'CONFIRMEE':
        color = AppColors.accentGreen;
        text = 'Reservation confirmee';
        break;
      case 'REJETEE':
        color = AppColors.statusRed;
        text = 'Reservation refusee par le conducteur';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [AppShadows.soft],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
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