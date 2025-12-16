import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/observation.dart';
import '../../../core/utils/debouncer.dart';
import '../../blocs/observation/observation_bloc.dart';
import '../../blocs/observation/observation_event.dart';
import '../../blocs/observation/observation_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/observation_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/offline_mode_indicator.dart';
import 'observation_detail_screen.dart';
import 'observation_form_screen.dart';

/// Screen displaying list of observations with search, filter, and pagination
class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({super.key});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Debouncer _searchDebouncer;
  
  bool _isSearching = false;
  ObservationFilters _currentFilters = const ObservationFilters();
  String? _currentUserId;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  List<Observation> _displayedObservations = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    
    // Get current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        setState(() {
          _currentUserId = authState.user.id;
        });
        // Load observations
        context.read<ObservationBloc>().add(LoadObservations(userId: _currentUserId));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreObservations();
    }
  }

  void _loadMoreObservations() {
    final state = context.read<ObservationBloc>().state;
    if (state is ObservationsLoaded) {
      final totalObservations = state.observations;
      final nextPage = _currentPage + 1;
      final startIndex = nextPage * _pageSize;
      
      if (startIndex < totalObservations.length) {
        setState(() {
          _currentPage = nextPage;
          final endIndex = (startIndex + _pageSize).clamp(0, totalObservations.length);
          _displayedObservations = totalObservations.sublist(0, endIndex);
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    // Show loading indicator immediately
    setState(() {
      _isSearching = true;
    });

    // Debounce search - wait 300ms after user stops typing
    _searchDebouncer.call(() {
      if (mounted) {
        if (query.isEmpty) {
          context.read<ObservationBloc>().add(LoadObservations(userId: _currentUserId));
        } else {
          context.read<ObservationBloc>().add(
            SearchObservations(query: query, userId: _currentUserId),
          );
        }
        
        // Hide loading indicator after triggering search
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    });
  }

  void _onRefresh() {
    context.read<ObservationBloc>().add(
      LoadObservations(forceRefresh: true, userId: _currentUserId),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: _currentFilters,
        onApply: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          
          if (filters.hasActiveFilters) {
            context.read<ObservationBloc>().add(
              ApplyFilters(
                species: filters.species,
                location: filters.location,
                startDate: filters.startDate,
                endDate: filters.endDate,
                userId: _currentUserId,
              ),
            );
          } else {
            context.read<ObservationBloc>().add(ClearFilters(userId: _currentUserId));
          }
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = const ObservationFilters();
      _searchController.clear();
    });
    context.read<ObservationBloc>().add(ClearFilters(userId: _currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Observations'),
        actions: [
          // Filter button with badge if filters are active
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filters',
              ),
              if (_currentFilters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Clear filters button (only show if filters are active)
          if (_currentFilters.hasActiveFilters || _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear all filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by species or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Active filters indicator
          if (_currentFilters.hasActiveFilters) _buildActiveFiltersChips(),

          // Observations list
          Expanded(
            child: BlocConsumer<ObservationBloc, ObservationState>(
              listener: (context, state) {
                if (state is ObservationsLoaded) {
                  // Reset pagination when new data loads
                  setState(() {
                    _currentPage = 0;
                    final endIndex = (_pageSize).clamp(0, state.observations.length);
                    _displayedObservations = state.observations.sublist(0, endIndex);
                  });
                }
              },
              builder: (context, state) {
                if (state is ObservationsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ObservationError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading observations',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ObservationsLoaded) {
                  if (state.observations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _onRefresh();
                      // Wait for the bloc to finish loading
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: Column(
                      children: [
                        // Offline/sync status banner
                        OfflineModeIndicator(
                          isOffline: state.isOffline,
                          pendingSyncCount: state.pendingSyncCount,
                          onSyncNow: () {
                            context
                                .read<ObservationBloc>()
                                .add(const SyncPendingObservations());
                          },
                        ),

                        // Observations list
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _displayedObservations.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _displayedObservations.length) {
                                // Show loading indicator at bottom if more items available
                                if (_displayedObservations.length < state.observations.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return const SizedBox(height: 80); // Space for FAB
                              }

                              final observation = _displayedObservations[index];
                              return ObservationCard(
                                observation: observation,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ObservationDetailScreen(
                                        observation: observation,
                                      ),
                                    ),
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

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ObservationFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Observation'),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final chips = <Widget>[];

    if (_currentFilters.species != null) {
      chips.add(
        Chip(
          label: Text('Species: ${_currentFilters.species}'),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _currentFilters = _currentFilters.copyWith(clearSpecies: true);
            });
            context.read<ObservationBloc>().add(
              ApplyFilters(
                location: _currentFilters.location,
                startDate: _currentFilters.startDate,
                endDate: _currentFilters.endDate,
                userId: _currentUserId,
              ),
            );
          },
        ),
      );
    }

    if (_currentFilters.location != null) {
      chips.add(
        Chip(
          label: Text('Location: ${_currentFilters.location}'),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _currentFilters = _currentFilters.copyWith(clearLocation: true);
            });
            context.read<ObservationBloc>().add(
              ApplyFilters(
                species: _currentFilters.species,
                startDate: _currentFilters.startDate,
                endDate: _currentFilters.endDate,
                userId: _currentUserId,
              ),
            );
          },
        ),
      );
    }

    if (_currentFilters.startDate != null && _currentFilters.endDate != null) {
      chips.add(
        Chip(
          label: Text(
            'Date: ${dateFormat.format(_currentFilters.startDate!)} - '
            '${dateFormat.format(_currentFilters.endDate!)}',
          ),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
                clearStartDate: true,
                clearEndDate: true,
              );
            });
            context.read<ObservationBloc>().add(
              ApplyFilters(
                species: _currentFilters.species,
                location: _currentFilters.location,
                userId: _currentUserId,
              ),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No observations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first observation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
