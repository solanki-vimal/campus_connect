import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/admin_settings_service.dart';
import '../../models/event.dart';

class CreateEventScreen extends StatefulWidget {
  /// If null, screen is in Add mode. If provided, screen is in Edit mode
  /// and the form is pre-filled from this event.
  final Event? existingEvent;

  const CreateEventScreen({this.existingEvent, super.key});

  bool get isEditMode => existingEvent != null;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _capacityController;
  final _eventService = EventService();
  final _settingsService = AdminSettingsService();

  String? _category;
  DateTime? _date;
  late bool _registrationRequired;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _venueController = TextEditingController(text: existing?.venue ?? '');
    _startTimeController = TextEditingController(text: existing?.startTime ?? '');
    _endTimeController = TextEditingController(text: existing?.endTime ?? '');
    _capacityController = TextEditingController(text: existing?.capacity?.toString() ?? '');
    _category = existing?.category ?? 'Academic';
    _date = existing?.date;
    _registrationRequired = existing?.registrationRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      controller.text = picked.format(context);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_date == null) {
      setState(() => _errorMessage = 'Please select a date');
      return;
    }

    final user = context.read<UserProvider>().appUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final capacity = (!_registrationRequired || _capacityController.text.trim().isEmpty)
        ? null
        : int.tryParse(_capacityController.text.trim());

    try {
      if (widget.isEditMode) {
        await _eventService.updateEvent(widget.existingEvent!.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category!,
          'date': Timestamp.fromDate(_date!),
          'startTime': _startTimeController.text.trim(),
          'endTime': _endTimeController.text.trim(),
          'venue': _venueController.text.trim(),
          'registrationRequired': _registrationRequired,
          'capacity': capacity,
        });
      } else {
        await _eventService.createEvent(
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category!,
          date: _date!,
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          venue: _venueController.text,
          organizerId: user.uid,
          organizerName: user.name,
          organizerType: user.role,
          department: user.department,
          club: user.club,
          registrationRequired: _registrationRequired,
          capacity: capacity,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode ? 'Event updated' : 'Event published',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to ${widget.isEditMode ? 'update' : 'submit'} event: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Shared input decoration factory
    InputDecoration inputDeco(String label, {String? hint, Widget? suffix}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        );

    // Tappable row that looks like a filled field
    Widget pickerField({
      required IconData icon,
      required String label,
      required String? value,
      required VoidCallback onTap,
      bool isRequired = false,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (isRequired && value == null)
                    ? colorScheme.error
                    : colorScheme.outline.withValues(alpha: 0.4)),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? label,
                  style: TextStyle(
                    fontSize: 16,
                    color: value == null
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'Edit Event' : 'Create Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // ── Event Details ───────────────────────────────────────
              _SectionLabel('Event Details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: inputDeco('Event Name',
                    hint: 'e.g. Demystifying Cloud Architecture'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Event name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: inputDeco('Description',
                    hint: 'Describe the event…'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),

              // Category dropdown
              StreamBuilder<List<String>>(
                stream: _settingsService.streamNames('event_categories'),
                builder: (context, snapshot) {
                  final cats = snapshot.data ?? [];
                  if (cats.isNotEmpty && !cats.contains(_category)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _category = cats.first);
                    });
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: cats.contains(_category) ? _category : null,
                    decoration: inputDeco('Category'),
                    hint: snapshot.connectionState == ConnectionState.waiting
                        ? const Text('Loading…')
                        : const Text('Select Category'),
                    items: cats
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                    validator: (v) =>
                        v == null ? 'Select a category' : null,
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Schedule ────────────────────────────────────────────
              _SectionLabel('Schedule'),
              const SizedBox(height: 12),

              // Date picker
              pickerField(
                icon: Icons.calendar_today_outlined,
                label: 'Select Date *',
                value: _date == null
                    ? null
                    : '${_date!.day} / ${_date!.month} / ${_date!.year}',
                onTap: _pickDate,
                isRequired: true,
              ),
              const SizedBox(height: 14),

              // Time row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      readOnly: true,
                      onTap: () => _pickTime(_startTimeController),
                      decoration: inputDeco('Start Time',
                          suffix: const Icon(Icons.access_time_outlined)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      readOnly: true,
                      onTap: () => _pickTime(_endTimeController),
                      decoration: inputDeco('End Time',
                          suffix: const Icon(Icons.access_time_outlined)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Location ────────────────────────────────────────────
              _SectionLabel('Location'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueController,
                decoration: inputDeco('Venue',
                    hint: 'e.g. Main Auditorium & CS Lab',
                    suffix: const Icon(Icons.place_outlined)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
              ),
              const SizedBox(height: 28),

              // ── Registration ────────────────────────────────────────
              _SectionLabel('Registration'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Registration Required',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Students register in-app; no external link needed',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _registrationRequired,
                  onChanged: (v) => setState(() => _registrationRequired = v),
                ),
              ),
              if (_registrationRequired) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Capacity (optional)',
                      hint: 'Leave blank for unlimited registrations',
                      suffix: const Icon(Icons.people_outline)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter a valid positive number';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Submit button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.isEditMode ? 'Update Event' : 'Publish Event'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small section label widget used between form groups.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

