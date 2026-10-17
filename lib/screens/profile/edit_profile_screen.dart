import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';

/// Edits only the `profiles/{uid}` document — never writes to `users`
/// (AppUser), so profile detail edits can't ever affect role/routing.
class EditProfileScreen extends StatefulWidget {
  final String uid;
  final String role;
  final UserProfile existingProfile;

  const EditProfileScreen({
    required this.uid,
    required this.role,
    required this.existingProfile,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = UserProfileService();

  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _roleFieldController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.existingProfile.phone ?? '');
    _bioController = TextEditingController(text: widget.existingProfile.bio ?? '');
    _roleFieldController = TextEditingController(text: _initialRoleFieldValue());
  }

  String _initialRoleFieldValue() {
    switch (widget.role) {
      case 'student':
        return widget.existingProfile.enrollmentNumber ?? '';
      case 'faculty':
        return widget.existingProfile.designation ?? '';
      case 'club_coordinator':
        return widget.existingProfile.clubPosition ?? '';
      default:
        return '';
    }
  }

  String _roleFieldLabel() {
    switch (widget.role) {
      case 'student':
        return 'Enrollment Number';
      case 'faculty':
        return 'Designation (e.g. Assistant Professor)';
      case 'club_coordinator':
        return 'Your Position in the Club (e.g. President)';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _roleFieldController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final roleFieldValue = _roleFieldController.text.trim().isEmpty
        ? null
        : _roleFieldController.text.trim();

    final updated = widget.existingProfile.copyWith(
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      enrollmentNumber: widget.role == 'student' ? roleFieldValue : null,
      designation: widget.role == 'faculty' ? roleFieldValue : null,
      clubPosition: widget.role == 'club_coordinator' ? roleFieldValue : null,
    );

    try {
      await _profileService.saveProfile(updated);
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleLabel = _roleFieldLabel();

    InputDecoration inputDeco(String label, {Widget? prefix}) => InputDecoration(
          labelText: label,
          prefixIcon: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),

              // ── Contact ─────────────────────────────────────────────
              _sectionLabel(context, 'Contact'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: inputDeco('Phone Number',
                    prefix: const Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 28),

              // ── Role-specific info ───────────────────────────────────
              if (roleLabel.isNotEmpty) ...[
                _sectionLabel(context, 'Role Details'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roleFieldController,
                  decoration: inputDeco(roleLabel,
                      prefix: const Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 28),
              ],

              // ── Bio ─────────────────────────────────────────────────
              _sectionLabel(context, 'About You'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: inputDeco('Bio (optional)'),
              ),
              const SizedBox(height: 40),

              // ── Save ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
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
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

