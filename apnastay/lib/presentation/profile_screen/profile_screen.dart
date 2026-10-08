import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../lifestyle_quiz_screen/lifestyle_quiz_screen.dart';
import '../pg_owner_onboarding_screen/pg_owner_onboarding_screen.dart';
import '../meal_provider_onboarding_screen/meal_provider_onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOwner;
  final bool isMealProvider;

  const ProfileScreen({
    super.key,
    this.isOwner = false,
    this.isMealProvider = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _authService.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    if (widget.isMealProvider) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MealProviderOnboardingScreen(
            isEditing: true,
            initialProfile: profile,
          ),
        ),
      );
      if (mounted) _loadProfile();
      return;
    }
    if (widget.isOwner) {
      try {
        final listings = await _authService.getMyPgs();
        if (!mounted) return;
        if (listings.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create a PG listing before editing it.'),
            ),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PgOwnerOnboardingScreen(
              isEditing: true,
              initialProfile: profile,
              initialListing: listings.first,
            ),
          ),
        );
        if (mounted) _loadProfile();
      } on AuthServiceException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LifestyleQuizScreen(initialProfile: profile, isEditing: true),
      ),
    );
    if (mounted) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final profile = _profile ?? const <String, dynamic>{};
    final name = profile['name']?.toString().trim().isNotEmpty == true
        ? profile['name'].toString()
        : user?.displayName ?? 'ApnaStay user';
    final email = profile['email']?.toString() ?? user?.email ?? '';
    final isMealProviderProfile =
        widget.isMealProvider || profile['role']?.toString() == 'meal_provider';
    final photoUrl =
        (widget.isOwner
                ? (profile['owner_photo_url'] ?? profile['photo_url'])
                : isMealProviderProfile
                ? (profile['provider_photo_url'] ?? profile['photo_url'])
                : profile['photo_url'] ?? profile['provider_photo_url'])
            ?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: widget.isOwner
                      ? AppTheme.secondaryBrandLight
                      : widget.isMealProvider
                      ? AppTheme.tertiaryBrandLight
                      : AppTheme.primaryBrandLight,
                  child: photoUrl == null || photoUrl.trim().isEmpty
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: widget.isOwner
                              ? AppTheme.secondaryBrand
                              : widget.isMealProvider
                              ? AppTheme.tertiaryBrand
                              : AppTheme.primaryBrand,
                        )
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Icon(
                              Icons.person,
                              size: 60,
                              color: widget.isMealProvider
                                  ? AppTheme.tertiaryBrand
                                  : AppTheme.primaryBrand,
                            ),
                            errorWidget: (_, _, _) => Icon(
                              Icons.person,
                              size: 60,
                              color: widget.isMealProvider
                                  ? AppTheme.tertiaryBrand
                                  : AppTheme.primaryBrand,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isOwner
                        ? AppTheme.secondaryBrand
                        : widget.isMealProvider
                        ? AppTheme.tertiaryBrand
                        : AppTheme.primaryBrand,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileOption(Icons.settings, 'Settings'),
              _buildProfileOption(Icons.history, 'Booking History'),
              _buildProfileOption(Icons.payment, 'Payment Methods'),
              _buildProfileOption(Icons.help_outline, 'Help & Support'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    foregroundColor: AppTheme.error,
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isOwner
                ? AppTheme.secondaryBrandLight
                : widget.isMealProvider
                ? AppTheme.tertiaryBrandLight
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: widget.isOwner
                ? AppTheme.secondaryBrand
                : widget.isMealProvider
                ? AppTheme.tertiaryBrand
                : AppTheme.primaryBrand,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.onSurfaceMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.outlineVariant),
        ),
        tileColor: AppTheme.surface,
        onTap: () {},
      ),
    );
  }
}
