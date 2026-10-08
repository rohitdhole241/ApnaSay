import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import './roommate_detail_screen.dart';
import './roommate_matching_screen.dart';

class LikedRoommatesScreen extends StatefulWidget {
  const LikedRoommatesScreen({super.key});

  @override
  State<LikedRoommatesScreen> createState() => _LikedRoommatesScreenState();
}

class _LikedRoommatesScreenState extends State<LikedRoommatesScreen> {
  final AuthService _authService = AuthService();
  List<RoommateModel> _roommates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLikedRoommates();
  }

  Future<void> _loadLikedRoommates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _authService.getLikedRoommates();
      if (!mounted) return;
      setState(() {
        _roommates = data.map(RoommateModel.fromApi).toList();
        _isLoading = false;
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your liked profiles. Please try again.';
        _isLoading = false;
      });
      debugPrint('Failed to load liked roommates: $error');
    }
  }

  void _openProfile(RoommateModel roommate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoommateDetailScreen(roommate: roommate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      title: Text(
        'Liked profiles',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadLikedRoommates,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          )
        : _roommates.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 48,
                    color: AppTheme.secondaryBrand,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No liked profiles yet',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Profiles you like will be saved here so you can open them later.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadLikedRoommates,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _roommates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final roommate = _roommates[index];
                final location = [roommate.locality, roommate.city]
                    .where((part) => part.isNotEmpty && part != 'Not specified')
                    .join(' · ');
                return Card(
                  color: AppTheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: _ProfileAvatar(roommate: roommate),
                    title: Text(
                      '${roommate.name}${roommate.age > 0 ? ', ${roommate.age}' : ''}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      location.isEmpty ? roommate.profession : location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => _openProfile(roommate),
                  ),
                );
              },
            ),
          ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  final RoommateModel roommate;

  const _ProfileAvatar({required this.roommate});

  @override
  Widget build(BuildContext context) {
    final imageUrl = roommate.imageUrl.trim();
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.secondaryBrandLight,
      child: ClipOval(
        child: SizedBox(
          width: 56,
          height: 56,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person_rounded, color: AppTheme.secondaryBrand)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    color: AppTheme.secondaryBrand,
                  ),
                ),
        ),
      ),
    );
  }
}
