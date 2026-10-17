import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_settings_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _settingsService = AdminSettingsService();

  String? _department;
  String? _selectedClub;

  String _selectedRole = 'student'; // student | faculty | club_coordinator

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      department: _department ?? '',
      selectedRole: _selectedRole,
      club: _selectedRole == 'club_coordinator' ? _selectedClub : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    if (error == null) {
      if (_selectedRole != 'student') {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Request Submitted'),
            content: Text(
              'Your ${_selectedRole == 'faculty' ? 'Faculty' : 'Club Coordinator'} '
                  'account request has been submitted. You can log in now, but you\'ll '
                  'see a pending-approval screen until a Super Admin approves your request.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join CampusConnect to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'I am signing up as',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'student', label: Text('Student', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 'faculty', label: Text('Faculty', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 'club_coordinator', label: Text('Club Coordinator', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedRole = selection.first);
                  },
                ),
                if (_selectedRole != 'student') ...[
                  const SizedBox(height: 8),
                  Text(
                    _selectedRole == 'faculty'
                        ? 'Faculty accounts require Super Admin approval before you can post notices or events.'
                        : 'Club Coordinator accounts require Super Admin approval before you can create events.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: 'College Email',
                    hintText: 'eg: 24ceubs148+s1@ddu.ac.in',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!AuthService.isCollegeEmail(v)) {
                      return 'Only @ddu.ac.in emails are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<String>>(
                  stream: AdminSettingsService().streamNames('departments'),
                  builder: (context, snapshot) {
                    final depts = snapshot.data ?? [];
                    if (depts.isNotEmpty && !depts.contains(_department)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _department = depts.first);
                      });
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: depts.contains(_department) ? _department : null,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.business_outlined),
                        labelText: 'Department',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                      ),
                      hint: snapshot.connectionState == ConnectionState.waiting
                          ? const Text('Loading departments...')
                          : const Text('Select Department'),
                      items: depts
                          .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _department = value);
                      },
                      validator: (v) => v == null ? 'Select your department' : null,
                    );
                  }
                ),

                if (_selectedRole == 'club_coordinator') ...[
                  const SizedBox(height: 16),
                  StreamBuilder<List<String>>(
                    stream: _settingsService.streamNames('clubs'),
                    builder: (context, snapshot) {
                      final clubs = snapshot.data ?? [];
                      if (clubs.isNotEmpty && _selectedClub != null && !clubs.contains(_selectedClub)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedClub = null);
                        });
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedClub,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.groups_outlined),
                          labelText: 'Club Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                        ),
                        hint: snapshot.connectionState == ConnectionState.waiting
                            ? const Text('Loading clubs...')
                            : const Text('Select your club'),
                        items: clubs
                            .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedClub = value),
                        validator: (v) {
                          if (_selectedRole == 'club_coordinator' && v == null) {
                            return 'Select your club name';
                          }
                          return null;
                        },
                      );
                    }
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}