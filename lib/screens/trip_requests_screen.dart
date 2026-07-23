import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../widgets/address_timeline_tile.dart';
import '../widgets/custom_button.dart';

class TripRequestsScreen extends StatefulWidget {
  const TripRequestsScreen({super.key});

  @override
  State<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends State<TripRequestsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final requests = await ReservationService.getPendingRequests();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _loading = false;
    });
  }

  Future<void> _accept(Map<String, dynamic> request) async {
    final id = request['reservationId']?.toString();
    if (id == null) return;
    setState(() => _processing.add(id));
    final result = await ReservationService.confirmReservation(id);
    if (!mounted) return;
    setState(() => _processing.remove(id));

    if (result.success) {
      setState(() => _requests.removeWhere(
            (r) => r['reservationId']?.toString() == id,
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation confirmee')),
      );
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Confirmation impossible',
        isAuthError: result.isAuthError,
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final id = request['reservationId']?.toString();
    if (id == null) return;
    setState(() => _processing.add(id));
    final result = await ReservationService.rejectReservation(id);
    if (!mounted) return;
    setState(() => _processing.remove(id));

    if (result.success) {
      setState(() => _requests.removeWhere(
            (r) => r['reservationId']?.toString() == id,
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation refusee')),
      );
    } else {
      showErrorSnackBar(
        context,
        result.message ?? 'Refus impossible',
        isAuthError: result.isAuthError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Demandes de reservation'),
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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _requests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.tray,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune demande en attente pour le moment',
                          textAlign: TextAlign.center,
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
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final id = request['reservationId']?.toString();
                      final isProcessing =
                          id != null && _processing.contains(id);
                      return _RequestCard(
                        request: request,
                        processing: isProcessing,
                        onAccept: () => _accept(request),
                        onReject: () => _reject(request),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final departure = request['departure']?.toString() ?? 'Depart';
    final arrival = request['arrival']?.toString() ?? 'Arrivee';
    final passager = request['passager']?.toString() ?? 'Passager';
    final nbPlaces = request['nbPlacesReservees']?.toString() ?? '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [AppShadows.soft],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddressTimelineTile(
            departure: departure,
            arrival: arrival,
            compact: true,
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  passager,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                CupertinoIcons.person_2,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$nbPlaces place(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Refuser',
                  secondary: true,
                  backgroundColor: AppColors.statusRed,
                  loading: processing,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Accepter',
                  backgroundColor: AppColors.accentGreen,
                  loading: processing,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}