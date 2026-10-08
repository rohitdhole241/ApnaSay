import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import './widgets/google_auth_button_widget.dart';
import './widgets/role_selector_widget.dart';

// TODO: Replace with Bloc/Riverpod for production
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

enum UserRole { user, pgOwner, mealProvider }

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.user;
  String? _gender;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pgNameController = TextEditingController();
  final _kitchenNameController = TextEditingController();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pgNameController.dispose();
    _kitchenNameController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      if (email.isEmpty || password.isEmpty) {
        _showMessage('Email and password are required to sign in.');
        return;
      }
    } else {
      if (_nameController.text.trim().isEmpty) {
        _showMessage('Enter your name to create an account.');
        return;
      }
      if (email.isEmpty) {
        _showMessage('Enter your email address.');
        return;
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        _showMessage('Enter a valid email address with @.');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showMessage('Enter your 10-digit mobile number.');
        return;
      }
      if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
        _showMessage('Mobile number must be exactly 10 digits.');
        return;
      }
      if (!_isPasswordValid(password)) {
        _showMessage(
          'Password must be 8+ chars with uppercase, lowercase, number and special character.',
        );
        return;
      }
      if (_selectedRole == UserRole.user && _gender == null) {
        _showMessage('Select your gender or choose "Prefer not to say".');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final profile = _isLogin
          ? await _authService.signIn(email: email, password: password)
          : await _authService.createAccount(
              name: _nameController.text,
              email: email,
              phone: _phoneController.text,
              password: password,
              role: _apiRoleFor(_selectedRole),
              pgName: _pgNameController.text,
              kitchenName: _kitchenNameController.text,
              gender: _selectedRole == UserRole.user ? _gender : null,
            );

      if (_isLogin) {
        final accountRole = profile['role']?.toString() ?? 'user';
        final selectedRole = _apiRoleFor(_selectedRole);
        if (accountRole != selectedRole) {
          await _authService.signOut();
          throw AuthServiceException(
            'This email is registered as ${_roleLabel(accountRole)}. Select that role to sign in.',
          );
        }
      }

      if (!mounted) return;
      final role = _roleFromApi(profile['role']);
      final needsUserProfile = role == UserRole.user &&
          (!_isLogin || !_hasRoommateBasics(profile));
      final route = needsUserProfile
          ? AppRoutes.lifestyleQuizScreen
          : _routeForRole(role, isNewAccount: !_isLogin);
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
        arguments: needsUserProfile ? profile : null,
      );
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not complete authentication: $error');
    }
  }

  bool _isPasswordValid(String password) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    ).hasMatch(password);
  }

  String _apiRoleFor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'user';
      case UserRole.pgOwner:
        return 'pg_owner';
      case UserRole.mealProvider:
        return 'meal_provider';
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'pg_owner':
        return 'PG Owner';
      case 'meal_provider':
        return 'Meal Provider';
      default:
        return 'Looking for PG';
    }
  }

  UserRole _roleFromApi(dynamic role) {
    switch (role) {
      case 'pg_owner':
        return UserRole.pgOwner;
      case 'meal_provider':
        return UserRole.mealProvider;
      default:
        return UserRole.user;
    }
  }

  String _routeForRole(UserRole role, {required bool isNewAccount}) {
    switch (role) {
      case UserRole.pgOwner:
        return isNewAccount
            ? AppRoutes.pgOwnerOnboardingScreen
            : AppRoutes.pgOwnerDashboardScreen;
      case UserRole.mealProvider:
        return isNewAccount
            ? AppRoutes.mealProviderOnboardingScreen
            : AppRoutes.mealProviderDashboardScreen;
      case UserRole.user:
        return isNewAccount
            ? AppRoutes.lifestyleQuizScreen
            : AppRoutes.homeDashboardScreen;
    }
  }

  bool _hasRoommateBasics(Map<String, dynamic> profile) {
    bool hasValue(String field) =>
        profile[field]?.toString().trim().isNotEmpty == true;

    // Legacy accounts skipped the profile form. Ask them to review their
    // location, budget, and gender before entering roommate matching.
    return hasValue('city') && hasValue('budget') && hasValue('gender');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 0 : 24,
              vertical: 24,
            ),
            child: isTablet
                ? Center(child: SizedBox(width: 480, child: _buildContent()))
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModeToggle(),
              const SizedBox(height: 24),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildAuthForm(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLegalText(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _getRoleColor(),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getRoleColor().withAlpha(77),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ApnaStay',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sorting your housing, roommates & food',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurfaceMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getRoleColor() {
    switch (_selectedRole) {
      case UserRole.user:
        return AppTheme.primaryBrand;
      case UserRole.pgOwner:
        return AppTheme.secondaryBrand;
      case UserRole.mealProvider:
        return AppTheme.tertiaryBrand;
    }
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Sign In',
            isActive: _isLogin,
            onTap: () {
              if (!_isLogin) _toggleMode();
            },
          ),
          _ToggleButton(
            label: 'Create Account',
            isActive: !_isLogin,
            onTap: () {
              if (_isLogin) _toggleMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'I am a...',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        RoleSelectorWidget(
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
        ),
        const SizedBox(height: 20),
        if (!_isLogin) ...[
          _buildTextField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 12),
          if (_selectedRole == UserRole.user) ...[
            _buildGenderDropdown(),
            const SizedBox(height: 12),
          ],
          _buildTextField(
            'Email Address',
            _emailController,
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Mobile Number',
            _phoneController,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Password',
            _passwordController,
            Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          if (_selectedRole == UserRole.pgOwner)
            _buildTextField(
              'PG Name',
              _pgNameController,
              Icons.home_work_outlined,
            ),
          if (_selectedRole == UserRole.mealProvider)
            _buildTextField(
              'Kitchen/Service Name',
              _kitchenNameController,
              Icons.restaurant_outlined,
            ),
          if (_selectedRole != UserRole.user) const SizedBox(height: 12),
        ] else ...[
          _buildTextField(
            'Email Address',
            _emailController,
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Password',
            _passwordController,
            Icons.lock_outline,
            obscureText: true,
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getRoleColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),
        const GoogleAuthButtonWidget(),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _toggleMode,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: _isLogin
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: _isLogin ? 'Sign Up' : 'Sign In',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.primaryBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : keyboardType,
      obscureText: obscureText && !_isPasswordVisible,
      inputFormatters: inputFormatters,
      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.onSurface),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.onSurfaceMuted),
        suffixIcon: obscureText
            ? IconButton(
                tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.onSurfaceMuted,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    const genders = [
      'Female',
      'Male',
      'Non-binary',
      'Prefer not to say',
    ];

    return DropdownButtonFormField<String>(
      value: _gender,
      isExpanded: true,
      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.onSurface),
      decoration: const InputDecoration(
        hintText: 'Gender',
        prefixIcon: Icon(Icons.wc_outlined, size: 20),
        contentPadding: EdgeInsets.symmetric(vertical: 16),
      ),
      items: genders
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (gender) => setState(() => _gender = gender),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildLegalText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'By continuing, you agree to our ',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppTheme.onSurfaceMuted,
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryBrand,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: ' and ',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.primaryBrand,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}
