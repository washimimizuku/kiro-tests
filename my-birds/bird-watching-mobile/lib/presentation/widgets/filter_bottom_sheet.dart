import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Filter options for observations
class ObservationFilters {
  final String? species;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;

  const ObservationFilters({
    this.species,
    this.location,
    this.startDate,
    this.endDate,
  });

  bool get hasActiveFilters =>
      species != null ||
      location != null ||
      startDate != null ||
      endDate != null;

  ObservationFilters copyWith({
    String? species,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool clearSpecies = false,
    bool clearLocation = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return ObservationFilters(
      species: clearSpecies ? null : (species ?? this.species),
      location: clearLocation ? null : (location ?? this.location),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  ObservationFilters clear() {
    return const ObservationFilters();
  }
}

/// Bottom sheet for filtering observations
class FilterBottomSheet extends StatefulWidget {
  final ObservationFilters initialFilters;
  final Function(ObservationFilters) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TextEditingController _speciesController;
  late TextEditingController _locationController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _speciesController = TextEditingController(text: widget.initialFilters.species);
    _locationController = TextEditingController(text: widget.initialFilters.location);
    _startDate = widget.initialFilters.startDate;
    _endDate = widget.initialFilters.endDate;
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _speciesController.clear();
      _locationController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  void _apply() {
    final filters = ObservationFilters(
      species: _speciesController.text.trim().isEmpty ? null : _speciesController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );
    widget.onApply(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasFilters = _speciesController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _startDate != null ||
        _endDate != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Observations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Species filter
              Text(
                'Species',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _speciesController,
                decoration: InputDecoration(
                  hintText: 'e.g., Robin, Eagle, Sparrow',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _speciesController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _speciesController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Location filter
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'e.g., Central Park, Forest Trail',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: _locationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _locationController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Date range filter
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectStartDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _startDate != null
                            ? dateFormat.format(_startDate!)
                            : 'Start Date',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectEndDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _endDate != null
                            ? dateFormat.format(_endDate!)
                            : 'End Date',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: hasFilters ? _clearAll : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
