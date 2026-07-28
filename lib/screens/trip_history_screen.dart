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
import '../widgets/fade_slide_in.dart';

class _StatusVisual {
  final String label;
  final Color color;

  const _StatusVisual(this.label, this.color);
}

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
    final items = role == 'driver'
        ? await _loadDriverHistory()
        : await _loadPassengerHistory();

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadPassengerHistory() async {
    final reservations = await ReservationService.getMyReservations();

    final items = <Map<String, dynamic>>[];
    for (final res in reservations) {
      final reservationId = res['id']?.toString();
      final tripId = res['trajetId']?.toString();
      if (reservationId == null || tripId == null) continue;

      final trip = await TripService.getTrajetById(tripId);
      if (trip == null) continue;

      final statutReservation = res['statutReservation']?.toString() ?? '';
      final cibleId = trip['conducteurId']?.toString();

      final isPastTrip = _isDateInPast(trip['dateDepart']?.toString()) ||
          trip['statut'] == 'TERMINE';

      bool reviewable =
          statutReservation == 'CONFIRMEE' && isPastTrip && cibleId != null;

      if (reviewable) {
        final already = await AvisService.hasReviewed(reservationId);
        if (already) reviewable = false;
      }

      final visual = _reservationStatusVisual(statutReservation);

      items.add({
        'reservationId': reservationId,
        'tripId': tripId,
        'departure': trip['departure'],
        'arrival': trip['arrival'],
        'statusLabel': visual.label,
        'statusColor': visual.color,
        'cibleId': cibleId,
        'reviewable': reviewable,
      });
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> _loadDriverHistory() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return [];

    final trips = await TripService.getTrajetsByConducteur(userId);

    final items = <Map<String, dynamic>>[];
    for (final trip in trips) {
      final tripId = trip['id']?.toString();
      if (tripId == null) continue;

      final reservations =
          await ReservationService.getReservationsForTrip(tripId);
      final confirmedCount = reservations
          .where((r) => r['statutReservation'] == 'CONFIRMEE')
          .length;

      final visual = _tripStatusVisual(trip['statut']?.toString() ?? '');

      items.add({
        'reservationId': null,
        'tripId': tripId,
        'departure': trip['departure'],
        'arrival': trip['arrival'],
        'statusLabel': visual.label,
        'statusColor': visual.color,
        'cibleId': null,
        'reviewable': false,
        'reservationCount': confirmedCount,
      });
    }
    return items;
  }

  _StatusVisual _reservationStatusVisual(String statut) {
    switch (statut) {
      case 'CONFIRMEE':
        return _StatusVisual('Confirmee', AppColors.accentGreen);
      case 'EN_ATTENTE':
        return _StatusVisual('En attente', AppColors.statusOrange);
      case 'REJETEE':
        return _StatusVisual('Refusee', AppColors.statusRed);
      case 'ANNULEE':
        return _StatusVisual('Annulee', AppColors.textSecondary);
      default:
        return _StatusVisual(
          statut.isEmpty ? 'Inconnu' : statut,
          AppColors.textSecondary,
        );
    }
  }

  _StatusVisual _tripStatusVisual(String statut) {
    switch (statut) {
      case 'EN_COURS':
        return _StatusVisual('En cours', AppColors.accentGreen);
      case 'TERMINE':
        return _StatusVisual('Termine', AppColors.textSecondary);
      case 'ANNULE':
        return _StatusVisual('Annule', AppColors.statusRed);
      case 'PLANIFIE':
        return _StatusVisual('Planifie', AppColors.statusOrange);
      default:
        return _StatusVisual(
          statut.isEmpty ? 'Inconnu' : statut,
          AppColors.textSecondary,
        );
    }
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
                      return FadeSlideIn(
                        index: index,
                        child: _HistoryCard(
                          item: item,
                          submitting: submitting,
                          onReview: () => _openReview(item),
                        ),
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
    final statusLabel = item['statusLabel']?.toString() ?? 'Inconnu';
    final statusColor = item['statusColor'] as Color? ?? AppColors.textSecondary;
    final reviewable = item['reviewable'] == true;
    final reservationCount = item['reservationCount'] as int?;

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
          AddressTimelineTile(
            departure: departure,
            arrival: arrival,
            compact: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatutBadge(label: statusLabel, color: statusColor),
              if (reservationCount != null) ...[
                const SizedBox(width: 10),
                Icon(
                  CupertinoIcons.person_2,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$reservationCount reservation(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
  final String label;
  final Color color;

  const _StatutBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
          label,
          key: ValueKey(label),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
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
                borderRadius: BorderRadius.circular(16),
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