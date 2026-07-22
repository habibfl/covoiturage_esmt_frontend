import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../services/trip_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/trip_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  late Future<List<Map<String, dynamic>>> _resultsFuture;
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
    _resultsFuture = TripService.getTrajets();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _resultsFuture = TripService.getTrajets(
        depart: _queryController.text.trim(),
      );
    });
  }

  void _clear() {
    _queryController.clear();
    _focusNode.unfocus();
    setState(() => _selectedFilter = 0);
    _search();
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                            onSubmitted: (_) => _search(),
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
                  onTap: () {
                    setState(() => _selectedFilter = index);
                    _search();
                  },
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
                                ? Colors.white
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _resultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final trips = snapshot.data ?? [];
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
                            'Aucun trajet trouve',
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
                    return TripCard(
                      trip: trips[index],
                      onReserve: () =>
                          context.go('/booking', extra: trips[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}