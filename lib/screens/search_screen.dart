import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/error_utils.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/trip_card.dart';

String _normalize(String input) {
  const accents = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
  const plain = 'aaaaaaeeeeiiiiooooouuuucn';
  var result = input.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], plain[i]);
  }
  return result;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = true;
  List<Map<String, dynamic>> _allTrips = [];
  String _query = '';
  bool _focused = false;

  final List<String> _filters = const [
    'Tous',
    'Ce matin',
    'Cet apres-midi',
    'Ce soir',
  ];
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _queryController.addListener(_onQueryChanged);
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);
    final result = await TripService.getTrajetsWithStatus();
    if (!mounted) return;
    setState(() {
      _allTrips = result.trips;
      _loading = false;
    });
    if (!result.success) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? 'Impossible de charger les trajets.',
      );
    }
  }

  void _onQueryChanged() {
    setState(() => _query = _queryController.text.trim());
  }

  List<Map<String, dynamic>> get _filteredTrips {
    if (_query.isEmpty) return _allTrips;
    final needle = _normalize(_query);
    return _allTrips.where((trip) {
      final departure = _normalize(trip['departure']?.toString() ?? '');
      final arrival = _normalize(trip['arrival']?.toString() ?? '');
      return departure.contains(needle) || arrival.contains(needle);
    }).toList();
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _queryController.clear();
    _focusNode.unfocus();
    setState(() => _selectedFilter = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recherche'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            focusNode: _focusNode,
                            onSubmitted: (_) => _focusNode.unfocus(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Ou allez-vous ?',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_focused) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: _clear, child: const Text('Annuler')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.onColor
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final trips = _filteredTrips;
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _query.isEmpty
                    ? 'Aucun trajet trouve'
                    : "Aucun trajet trouve pour '$_query'",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Modifier la recherche',
                secondary: true,
                onPressed: _clear,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return FadeSlideIn(
          index: index,
          child: TripCard(
            trip: trips[index],
            onReserve: () => context.go('/booking', extra: trips[index]),
          ),
        );
      },
    );
  }
}
