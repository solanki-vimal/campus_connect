import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notice_service.dart';
import '../../services/admin_settings_service.dart';
import '../../models/notice.dart';

class CreateNoticeScreen extends StatefulWidget {
  /// If null, screen is in Add mode. If provided, screen is in Edit mode
  /// and the form is pre-filled from this notice.
  final Notice? existingNotice;

  const CreateNoticeScreen({this.existingNotice, super.key});

  bool get isEditMode => existingNotice != null;

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _noticeService = NoticeService();
  final _settingsService = AdminSettingsService();

  String? _category;
  String _department = 'all'; // 'all' is always available as a special option
  late String _priority; // normal | important | urgent
  DateTime? _expiryDate;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingNotice;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _category = existing?.category; // null = not yet selected (dynamic load)
    _department = existing?.department ?? 'all';
    _priority = existing?.priority ?? 'normal';
    _expiryDate = existing?.expiryDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<UserProvider>().appUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEditMode) {
        await _noticeService.updateNotice(widget.existingNotice!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category!,
          'department': _department,
          'priority': _priority,
          'expiryDate': _expiryDate != null
              ? Timestamp.fromDate(_expiryDate!)
              : FieldValue.delete(),
        });
      } else {
        await _noticeService.createNotice(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category!,
          department: _department,
          priority: _priority,
          postedBy: user.uid,
          postedByName: user.name,
          expiryDate: _expiryDate,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditMode ? 'Notice updated' : 'Notice posted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to ${widget.isEditMode ? 'update' : 'post'} notice: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    InputDecoration inputDeco(String label, {String? hint, Widget? suffix}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'Edit Notice' : 'Create Notice',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ── Notice Details section ──────────────────────────────
              Text('Notice Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: inputDeco('Title',
                    hint: 'e.g. Mid-Semester Examination Schedule'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: inputDeco('Description',
                    hint: 'Write your announcement here…'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 28),

              // ── Audience section ────────────────────────────────────
              Text('Audience',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Category
              StreamBuilder<List<String>>(
                stream: _settingsService.streamNames('notice_categories'),
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
                    validator: (v) => v == null ? 'Select a category' : null,
                  );
                },
              ),
              const SizedBox(height: 14),

              // Department
              StreamBuilder<List<String>>(
                stream: _settingsService.streamNames('departments'),
                builder: (context, snapshot) {
                  final depts = ['all', ...snapshot.data ?? []];
                  return DropdownButtonFormField<String>(
                    initialValue: depts.contains(_department) ? _department : 'all',
                    decoration: inputDeco('Department',
                        hint: '"All (General)" makes this college-wide'),
                    items: depts
                        .map((d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(d == 'all' ? 'All (General)' : d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _department = v);
                    },
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Priority ────────────────────────────────────────────
              Text('Priority',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'normal', label: Text('Normal')),
                  ButtonSegment(value: 'important', label: Text('Important')),
                  ButtonSegment(value: 'urgent', label: Text('Urgent')),
                ],
                selected: {_priority},
                onSelectionChanged: (s) =>
                    setState(() => _priority = s.first),
              ),
              const SizedBox(height: 14),

              // Expiry date
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickExpiryDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.4)),
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _expiryDate == null
                              ? 'Expiry Date (optional)'
                              : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: TextStyle(
                            color: _expiryDate == null
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (_expiryDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _expiryDate = null),
                          child: Icon(Icons.close,
                              size: 18, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Text(_errorMessage!,
                    style: TextStyle(color: colorScheme.error)),
                const SizedBox(height: 12),
              ],

              // ── Submit ──────────────────────────────────────────────
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
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.isEditMode ? 'Update Notice' : 'Post Notice'),
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
