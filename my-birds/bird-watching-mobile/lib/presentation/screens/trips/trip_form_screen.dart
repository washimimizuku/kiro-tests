import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/trip/trip_bloc.dart';
import '../../blocs/trip/trip_event.dart';
import '../../blocs/trip/trip_state.dart';
import '../../../data/models/trip.dart';

/// Screen for creating or editing a trip
/// Handles form validation and submission
class TripFormScreen extends StatefulWidget {
  final Trip? trip;

  const TripFormScreen({
    super.key,
    this.trip,
  });

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  bool get _isEditMode => widget.trip != null;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill form if editing
    if (_isEditMode) {
      _nameController.text = widget.trip!.name;
      _locationController.text = widget.trip!.location;
      _descriptionController.text = widget.trip!.description ?? '';
      _selectedDate = widget.trip!.tripDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Trip Date',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();
    
    if (_isEditMode) {
      // Update existing trip
      final updatedTrip = widget.trip!.copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        tripDate: _selectedDate,
        updatedAt: now,
      );

      context.read<TripBloc>().add(UpdateTrip(updatedTrip));
    } else {
      // Create new trip
      final newTrip = Trip(
        id: '', // Will be assigned by backend
        userId: '', // Will be assigned by backend
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        tripDate: _selectedDate,
        observationCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      context.read<TripBloc>().add(CreateTrip(newTrip));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Trip' : 'Create Trip'),
        elevation: 0,
      ),
      body: BlocListener<TripBloc, TripState>(
        listener: (context, state) {
          if (state is TripCreated || state is TripUpdated) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditMode ? 'Trip updated successfully' : 'Trip created successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate back
            Navigator.pop(context);
          } else if (state is TripError) {
            setState(() {
              _isSubmitting = false;
            });

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    hintText: 'e.g., Spring Migration 2024',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.tripName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),

                // Date picker
                InkWell(
                  onTap: _isSubmitting ? null : _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Trip Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(_selectedDate),
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Central Park, New York',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.locationName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add notes about this trip...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.tripDescription,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update Trip' : 'Create Trip',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
