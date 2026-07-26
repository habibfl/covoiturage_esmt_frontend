import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/avis_service.dart';
import '../services/error_utils.dart';
import '../services/reservation_service.dart';
import '../services/trip_service.dart';
import '../widgets/address_timeline_tile.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _submitting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final role = await AuthService.getRole();
    final reservations = await ReservationService.getMyReservations();

    final items = <Map<String, dynamic>>[];
    for (final res in reservations) {
      final reservationId = res['id']?.toString();
      final tripId = res['trajetId']?.toString();
      if (reservationId == null || tripId == null) continue;

      final trip = await TripService.getTrajetById(tripId);
      if (trip == null) continue;

      final statutReservation = res['statutReservation']?.toString() ?? '';
      final conducteurId = trip['conducteurId']?.toString();
      final isPassenger = role != 'driver';
      final cibleId = isPassenger ? conducteurId : null;

      final isPastTrip = _isDateInPast(trip['dateDepart']?.toString()) ||
          trip['statut'] == 'TERMINE';

      bool reviewable =
          statutReservation == 'CONFIRMEE' && isPastTrip && cibleId != null;

      if (reviewable) {
        final already = await AvisService.hasReviewed(reservationId);
        if (already) reviewable = false;
      }

      items.add({
        'reservationId': reservationId,
        'tripId': tripId,
        'departure': trip['departure'],
        'arrival': trip['arrival'],
        'statutReservation': statutReservation,
        'cibleId': cibleId,
        'reviewable': reviewable,
      });
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  bool _isDateInPast(String? dateStr) {
    if (dateStr == null) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  Future<void> _openReview(Map<String, dynamic> item) async {
    final reservationId = item['reservationId']?.toString();
    final cibleId = item['cibleId']?.toString();
    if (reservationId == null || cibleId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ReviewDialog(),
    );
    if (result == null || !mounted) return;

    final note = result['note'] as int;
    final commentaire = result['commentaire'] as String?;

    setState(() => _submitting.add(reservationId));

    final avisResult = await AvisService.createAvis(
      reservationId: reservationId,
      cibleId: cibleId,
      note: note,
      commentaire: commentaire,
    );

    if (!mounted) return;
    setState(() => _submitting.remove(reservationId));

    if (avisResult.success) {
      setState(() {
        final index = _items.indexWhere(
          (i) => i['reservationId']?.toString() == reservationId,
        );
        if (index != -1) {
          _items[index] = {..._items[index], 'reviewable': false};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis envoye, merci !')),
      );
    } else {
      showErrorSnackBar(
        context,
        avisResult.message ?? "Impossible d'envoyer l'avis",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des trajets'),
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
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Aucun trajet pour l'instant",
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
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final reservationId = item['reservationId']?.toString();
                      final submitting = reservationId != null &&
                          _submitting.contains(reservationId);
                      return _HistoryCard(
                        item: item,
                        submitting: submitting,
                        onReview: () => _openReview(item),
                      );
                    },
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool submitting;
  final VoidCallback onReview;

  const _HistoryCard({
    required this.item,
    required this.submitting,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final departure = item['departure']?.toString() ?? 'Depart';
    final arrival = item['arrival']?.toString() ?? 'Arrivee';
    final statutReservation = item['statutReservation']?.toString() ?? '';
    final reviewable = item['reviewable'] == true;

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
          const SizedBox(height: 12),
          Row(
            children: [
              _StatutBadge(statut: statutReservation),
              const Spacer(),
              if (reviewable)
                SizedBox(
                  height: 34,
                  width: 160,
                  child: OutlinedButton(
                    onPressed: submitting ? null : onReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: submitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text('Laisser un avis'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final String statut;

  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (statut) {
      case 'CONFIRMEE':
        color = AppColors.accentGreen;
        label = 'Confirmee';
        break;
      case 'EN_ATTENTE':
        color = AppColors.statusOrange;
        label = 'En attente';
        break;
      case 'REJETEE':
        color = AppColors.statusRed;
        label = 'Refusee';
        break;
      case 'ANNULEE':
        color = AppColors.textSecondary;
        label = 'Annulee';
        break;
      default:
        color = AppColors.textSecondary;
        label = statut.isEmpty ? 'Inconnu' : statut;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.onColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _note = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Laisser un avis',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final filled = index < _note;
              return IconButton(
                onPressed: () => setState(() => _note = index + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.starYellow,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
            decoration: InputDecoration(
              hintText: 'Commentaire (optionnel)',
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _note == 0
              ? null
              : () => Navigator.pop(context, {
                    'note': _note,
                    'commentaire': _commentController.text.trim(),
                  }),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}