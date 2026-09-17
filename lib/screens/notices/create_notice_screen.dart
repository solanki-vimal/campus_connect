import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notice_service.dart';
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

  static const List<String> _categories = [
    'General',
    'Academic',
    'Examination',
    'Holiday',
    'Placement',
    'Workshop',
    'Fee/Admin',
    'Emergency',
  ];

  static const List<String> _departments = ['all', 'CSE', 'IT', 'Civil', 'Mechanical', 'Electrical'];

  late String _category;
  late String _department;
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
    _category = existing?.category ?? 'General';
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
          'category': _category,
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
          category: _category,
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'Edit Notice' : 'Create Notice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _department,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  helperText: '"All" makes this a general, college-wide notice',
                ),
                items: _departments
                    .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d == 'all' ? 'All (General)' : d),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _department = v!),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'normal', label: Text('Normal')),
                  ButtonSegment(value: 'important', label: Text('Important')),
                  ButtonSegment(value: 'urgent', label: Text('Urgent')),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) => setState(() => _priority = selection.first),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _expiryDate == null
                      ? 'Expiry Date (optional)'
                      : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (_expiryDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiryDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickExpiryDate,
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.isEditMode ? 'Update Notice' : 'Post Notice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
