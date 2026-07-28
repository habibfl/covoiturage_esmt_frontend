import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/avis_service.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../widgets/address_timeline_tile.dart';
import '../widgets/custom_button.dart';
import '../widgets/driver_profile_card.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;

  const BookingScreen({super.key, this.trip});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _loading = false;
  double _driverRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final conducteurId = widget.trip?['conducteurId'];
    if (conducteurId == null) return;
    final rating = await AvisService.getNoteMoyenne(conducteurId.toString());
    if (!mounted) return;
    setState(() => _driverRating = rating);
  }

  Future<void> _reserve() async {
    final trip = widget.trip;
    final tripId = trip?['id']?.toString();
    if (tripId == null || tripId.isEmpty) {
      showErrorSnackBar(context, 'Trajet invalide, reessayez.');
      return;
    }
    setState(() => _loading = true);
    final result = await ReservationService.createReservation(tripId);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go(
        '/tracking',
        extra: {'tripId': tripId, 'reservationId': result.reservationId},
      );
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Reservation impossible',
        isAuthError: result.isAuthError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    if (trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Details du trajet'),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun trajet selectionne',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final departure = trip['departure']?.toString() ?? 'Depart non renseigne';
    final arrival = trip['arrival']?.toString() ?? 'Arrivee non renseignee';
    final driverName = trip['driverName']?.toString();
    final vehicle = trip['vehicle']?.toString() ?? '';
    final time = trip['time']?.toString();
    final seats = trip['seats'];
    final price = trip['price']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Details du trajet'),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [AppShadows.soft],
            ),
            child: AddressTimelineTile(departure: departure, arrival: arrival),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'DETAILS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 16),
          if (driverName != null && driverName.isNotEmpty)
            DriverProfileCard(
              name: driverName,
              vehicle: vehicle,
              rating: _driverRating,
              framed: true,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [AppShadows.soft],
              ),
              child: Text(
                'Conducteur non renseigne',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
          _MetaGrid(
            items: [
              _MetaItem(label: 'Heure', value: time ?? '--:--'),
              _MetaItem(label: 'Places', value: seats?.toString() ?? '—'),
              _MetaItem(label: 'Prix', value: price ?? 'A convenir'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CustomButton(
            label: 'Reserver cette place',
            loading: _loading,
            onPressed: _reserve,
          ),
        ),
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  final List<_MetaItem> items;

  const _MetaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _MetaCell(item: items[i])),
            if (i != items.length - 1)
              Container(width: 1, height: 36, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _MetaItem {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});
}

class _MetaCell extends StatelessWidget {
  final _MetaItem item;

  const _MetaCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(item.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}