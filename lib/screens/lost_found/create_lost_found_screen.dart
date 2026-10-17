import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/lost_found_service.dart';
import '../../services/admin_settings_service.dart';
import '../../services/image_upload_service.dart';

class CreateLostFoundScreen extends StatefulWidget {
  const CreateLostFoundScreen({super.key});

  @override
  State<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends State<CreateLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _service = LostFoundService();
  final _settingsService = AdminSettingsService();

  String _type = 'lost';
  String? _category;
  DateTime _date = DateTime.now();
  XFile? _pickedImage;   // locally picked file (not yet uploaded)
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImage(String source) async {
    setState(() => _isUploadingImage = true);
    try {
      final file = await ImageUploadService.pickImage(source);
      if (file != null) setState(() => _pickedImage = file);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Add Photo',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.blue),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage('camera');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Colors.purple),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick from your photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage('gallery');
                },
              ),
              if (_pickedImage != null) ...[
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _pickedImage = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<UserProvider>().appUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Upload image first if one was picked
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ImageUploadService.uploadFile(
          file: _pickedImage!,
          folder: 'lost_found',
        );
      }

      await _service.createItem(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category ?? 'Other',
        location: _locationController.text,
        date: _date,
        type: _type,
        postedBy: user.uid,
        postedByName: user.name,
        contactInfo: _contactController.text,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'lost'
                ? 'Lost item reported successfully'
                : 'Found item reported successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    InputDecoration inputDeco(String label, {String? hint, Widget? prefix}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefix,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor:
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Report Lost / Found',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [

            // ── Type toggle ──────────────────────────────────────────
            _SectionLabel('What are you reporting?'),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: 'lost',
                    label: Text('Lost Item'),
                    icon: Icon(Icons.search_off_outlined)),
                ButtonSegment(
                    value: 'found',
                    label: Text('Found Item'),
                    icon: Icon(Icons.inventory_2_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 28),

            // ── Photo ────────────────────────────────────────────────
            _SectionLabel('Photo (optional)'),
            const SizedBox(height: 12),
            _ImagePicker(
              pickedImage: _pickedImage,
              isLoading: _isUploadingImage,
              onTap: _showImageSourceSheet,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 28),

            // ── Item Details ─────────────────────────────────────────
            _SectionLabel('Item Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: inputDeco('Item Name *',
                  hint: 'e.g. Black Wallet, Blue Water Bottle'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Item name is required'
                  : null,
            ),
            const SizedBox(height: 14),

            StreamBuilder<List<String>>(
              stream: _settingsService.streamNames('lost_found_categories'),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                if (categories.isNotEmpty && _category == null) {
                  _category = categories.first;
                }
                return DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: inputDeco('Category *'),
                  hint: snapshot.connectionState == ConnectionState.waiting
                      ? const Text('Loading…')
                      : const Text('Select Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: inputDeco('Description *',
                  hint: 'Color, brand, any identifying features…'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 28),

            // ── Location & Date ──────────────────────────────────────
            _SectionLabel('Location & Date'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: inputDeco(
                _type == 'lost'
                    ? 'Where did you lose it? *'
                    : 'Where did you find it? *',
                hint: 'e.g. Library 2nd Floor, Canteen, Block A',
                prefix: const Icon(Icons.place_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 14),

            // Date picker row
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
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
                        size: 18,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _type == 'lost' ? 'Date Lost' : 'Date Found',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_date.day} / ${_date.month} / ${_date.year}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('Change',
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Contact ──────────────────────────────────────────────
            _SectionLabel('Contact'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactController,
              decoration: inputDeco(
                'Your Contact Info *',
                hint: 'Phone number or email so people can reach you',
                prefix: const Icon(Icons.contact_page_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Contact info is required'
                  : null,
            ),
            const SizedBox(height: 28),

            // ── Submit ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_type == 'lost'
                        ? Icons.search_off_outlined
                        : Icons.inventory_2_outlined),
                label: Text(
                  _isLoading
                      ? 'Submitting…'
                      : _type == 'lost'
                          ? 'Report Lost Item'
                          : 'Report Found Item',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Image Picker Widget ──────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final XFile? pickedImage;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ImagePicker({
    required this.pickedImage,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (pickedImage != null) {
      // Show selected image with an edit overlay
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(pickedImage!.path),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state — dashed-border upload prompt
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_outlined,
                  size: 28, color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text('Tap to add a photo',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Camera or Gallery',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────

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
