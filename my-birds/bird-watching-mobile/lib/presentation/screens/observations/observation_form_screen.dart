import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/observation.dart';
import '../../../data/models/trip.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../blocs/observation/observation_bloc.dart';
import '../../blocs/observation/observation_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/location_picker.dart';

/// Screen for creating or editing observations
/// Includes form validation and offline support
class ObservationFormScreen extends StatefulWidget {
  final Observation? observation; // null for create, non-null for edit
  final String? initialTripId;

  const ObservationFormScreen({
    super.key,
    this.observation,
    this.initialTripId,
  });

  @override
  State<ObservationFormScreen> createState() => _ObservationFormScreenState();
}

class _ObservationFormScreenState extends State<ObservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  File? _selectedPhoto;
  String? _selectedTripId;
  bool _isShared = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing observation data if editing
    if (widget.observation != null) {
      _speciesController.text = widget.observation!.speciesName;
      _locationController.text = widget.observation!.location;
      _notesController.text = widget.observation!.notes ?? '';
      _selectedDate = widget.observation!.observationDate;
      _latitude = widget.observation!.latitude;
      _longitude = widget.observation!.longitude;
      _selectedTripId = widget.observation!.tripId;
      _isShared = widget.observation!.isShared;
    } else if (widget.initialTripId != null) {
      _selectedTripId = widget.initialTripId;
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onPhotoSelected(File? photo) {
    setState(() {
      _selectedPhoto = photo;
    });
  }

  void _onLocationSelected(double latitude, double longitude) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date is not in the future
    final dateError = Validators.notFutureDate(_selectedDate);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final observation = Observation(
        id: widget.observation?.id ?? const Uuid().v4(),
        userId: authState.user.id,
        tripId: _selectedTripId,
        speciesName: _speciesController.text.trim(),
        observationDate: _selectedDate,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photoUrl: widget.observation?.photoUrl,
        localPhotoPath: _selectedPhoto?.path,
        isShared: _isShared,
        pendingSync: false, // Will be set by repository if offline
        createdAt: widget.observation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.observation == null) {
        // Create new observation
        context.read<ObservationBloc>().add(CreateObservation(observation));
      } else {
        // Update existing observation
        context.read<ObservationBloc>().add(UpdateObservation(observation));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.observation == null
                  ? 'Observation created successfully'
                  : 'Observation updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.observation != null;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Observation' : 'New Observation'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Species name
            Semantics(
              label: AccessibilityUtils.formFieldLabel(
                fieldName: 'Species Name',
                isRequired: true,
                currentValue: _speciesController.text,
              ),
              textField: true,
              child: TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species Name *',
                  hintText: 'e.g., American Robin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.speciesName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            Semantics(
              label: AccessibilityUtils.datePickerLabel(_selectedDate),
              button: true,
              enabled: !_isSubmitting,
              child: InkWell(
                onTap: _isSubmitting ? null : _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Observation Date *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateFormat.format(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            Semantics(
              label: AccessibilityUtils.formFieldLabel(
                fieldName: 'Location',
                isRequired: true,
                currentValue: _locationController.text,
              ),
              textField: true,
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g., Central Park',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.locationName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(height: 24),

            // GPS Location Picker
            LocationPicker(
              initialLatitude: _latitude,
              initialLongitude: _longitude,
              onLocationSelected: _onLocationSelected,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),

            // Photo Picker
            PhotoPicker(
              initialPhoto: _selectedPhoto,
              onPhotoSelected: _onPhotoSelected,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),

            // Notes
            Semantics(
              label: AccessibilityUtils.formFieldLabel(
                fieldName: 'Notes',
                isRequired: false,
                currentValue: _notesController.text,
              ),
              textField: true,
              multiline: true,
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any additional observations...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 1000,
                validator: Validators.notes,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(height: 16),

            // Share toggle
            Semantics(
              label: 'Share with community, ${_isShared ? 'enabled' : 'disabled'}',
              hint: 'Double tap to ${_isShared ? 'disable' : 'enable'} sharing',
              toggled: _isShared,
              child: SwitchListTile(
                title: const Text('Share with community'),
                subtitle: const Text('Allow other users to see this observation'),
                value: _isShared,
                onChanged: _isSubmitting ? null : (value) {
                  setState(() {
                    _isShared = value;
                  });
                },
                secondary: const Icon(Icons.share),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            Semantics(
              label: isEditing ? 'Update observation' : 'Create observation',
              hint: _isSubmitting ? 'Submitting...' : 'Double tap to submit',
              button: true,
              enabled: !_isSubmitting,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Observation' : 'Create Observation',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your observation will be saved locally and synced when you have an internet connection.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
