import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/empty_state_widget.dart';
import './roommate_detail_screen.dart';
import './liked_roommates_screen.dart';
import './roommate_requests_screen.dart';
import './widgets/roommate_card_widget.dart';

class RoommateMatchingScreen extends StatefulWidget {
  const RoommateMatchingScreen({super.key});
  @override
  State<RoommateMatchingScreen> createState() => _RoommateMatchingScreenState();
}

class _RoommateMatchingScreenState extends State<RoommateMatchingScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _filters = const ['All', 'Female', 'Male', 'Vegetarian', 'Non-smoker'];
  List<RoommateModel> _allProfiles = [];
  List<RoommateModel> _profiles = [];
  int _currentIndex = 0;
  int _likeCount = 0;
  int _passCount = 0;
  int _pendingRequestCount = 0;
  int _navIndex = 1;
  int _selectedFilter = 0;
  bool _isLoading = true;
  bool _isAnimatingOut = false;
  String? _loadError;
  late AnimationController _exitController;
  late Animation<Offset> _exitAnimation;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _exitAnimation = const AlwaysStoppedAnimation(Offset.zero);
    _loadRoommates();
    _loadPendingRoommateRequestCount();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _loadRoommates() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await _authService.getRoommates();
      final decisions = await _authService.getRoommateDecisions();
      if (!mounted) return;
      _allProfiles = data.map(RoommateModel.fromApi).toList();
      _likeCount = decisions.where((item) => item['decision'] == 'like').length;
      _passCount = decisions.where((item) => item['decision'] == 'pass').length;
      _applyFilter(_selectedFilter, resetIndex: true);
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _allProfiles = [];
        _profiles = [];
        _isLoading = false;
        _loadError = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _allProfiles = [];
        _profiles = [];
        _isLoading = false;
        _loadError = 'Roommate data could not be read. Please try again.';
      });
      debugPrint('Failed to load roommate profiles: $error');
    }
  }

  void _applyFilter(int index, {bool resetIndex = true}) {
    final filter = _filters[index];
    final filtered = switch (filter) {
      'Female' =>
        _allProfiles.where((p) => p.gender.toLowerCase() == 'female').toList(),
      'Male' =>
        _allProfiles.where((p) => p.gender.toLowerCase() == 'male').toList(),
      'Vegetarian' =>
        _allProfiles
            .where((p) => p.foodPreference.toLowerCase().contains('veget'))
            .toList(),
      'Non-smoker' =>
        _allProfiles
            .where(
              (p) => !p.lifestyleTags.any(
                (tag) => tag.toLowerCase().contains('smok'),
              ),
            )
            .toList(),
      _ => List<RoommateModel>.from(_allProfiles),
    };
    setState(() {
      _selectedFilter = index;
      _profiles = filtered;
      if (resetIndex) _currentIndex = 0;
    });
  }

  Future<void> _handleDecision(bool liked) async {
    if (_isAnimatingOut || _currentIndex >= _profiles.length) return;
    final roommate = _profiles[_currentIndex];
    if (roommate.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This profile cannot be saved right now.'),
        ),
      );
      return;
    }
    setState(() {
      _isAnimatingOut = true;
      _exitAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(liked ? 2 : -2, -0.3),
      ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
    });
    try {
      final saveFuture = _authService.saveRoommateDecision(
        targetUid: roommate.id,
        liked: liked,
      );
      await _exitController.forward(from: 0);
      await saveFuture;
      if (!mounted) return;
      setState(() {
        liked ? _likeCount++ : _passCount++;
        _currentIndex++;
        _isAnimatingOut = false;
        _exitController.reset();
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnimatingOut = false;
        _exitController.reset();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnimatingOut = false;
        _exitController.reset();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this decision. Please try again.'),
        ),
      );
      debugPrint('Failed to save roommate decision: $error');
    }
  }

  void _openLikedRoommates() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LikedRoommatesScreen()));
  }

  Future<void> _loadPendingRoommateRequestCount() async {
    try {
      final requests = await _authService.getRoommateRequests();
      final count = requests
          .where(
            (request) =>
                request['direction'] == 'incoming' &&
                request['status'] == 'pending',
          )
          .length;
      if (mounted) setState(() => _pendingRequestCount = count);
    } catch (error) {
      debugPrint('Could not load pending roommate request count: $error');
    }
  }

  Future<void> _openRoommateRequests() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RoommateRequestsScreen()));
    if (mounted) _loadPendingRoommateRequestCount();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Find Roommates',
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        _StatChip(
          icon: Icons.favorite_rounded,
          count: _likeCount,
          color: AppTheme.secondaryBrand,
          tooltip: 'Like current profile',
          onTap: _isAnimatingOut || _currentIndex >= _profiles.length
              ? null
              : () => _handleDecision(true),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.close_rounded,
          count: _passCount,
          color: AppTheme.onSurfaceMuted,
          tooltip: 'Pass current profile',
          onTap: _isAnimatingOut || _currentIndex >= _profiles.length
              ? null
              : () => _handleDecision(false),
        ),
        IconButton(
          tooltip: 'View liked profiles',
          onPressed: _openLikedRoommates,
          icon: const Icon(Icons.bookmarks_outlined),
        ),
        IconButton(
          tooltip: 'Roommate requests',
          onPressed: _openRoommateRequests,
          icon: Badge(
            isLabelVisible: _pendingRequestCount > 0,
            label: Text(
              _pendingRequestCount > 99 ? '99+' : '$_pendingRequestCount',
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_filters[index]),
                selected: index == _selectedFilter,
                onSelected: (_) => _applyFilter(index),
                selectedColor: AppTheme.secondaryBrandLight,
                checkmarkColor: AppTheme.secondaryBrand,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCardStack(),
        ),
      ],
    ),
    bottomNavigationBar: AppNavigation(
      currentIndex: _navIndex,
      onTap: (index) {
        if (index == 2) {
          _openRoommateRequests();
        } else {
          setState(() => _navIndex = index);
        }
      },
    ),
  );

  Widget _buildCardStack() {
    if (_loadError != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load roommates',
        subtitle: _loadError!,
        ctaLabel: 'Try again',
        onCta: _loadRoommates,
        iconColor: AppTheme.error,
      );
    }

    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      final hasProfiles = _allProfiles.isNotEmpty;
      final hasFilterResults = _profiles.isNotEmpty;
      final hasSeenProfiles = _likeCount + _passCount > 0;
      final hasSavedLikes = _likeCount > 0;
      return EmptyStateWidget(
        icon: hasProfiles || hasSeenProfiles
            ? Icons.favorite_border_rounded
            : Icons.people_outline_rounded,
        title: !hasProfiles
            ? hasSeenProfiles
                  ? 'You have seen everyone'
                  : 'No roommate profiles yet'
            : !hasFilterResults
            ? 'No profiles match this filter'
            : 'You have seen everyone',
        subtitle: !hasProfiles
            ? hasSeenProfiles
                  ? 'Your decisions are saved. You can revisit liked profiles or refresh later for new roommates.'
                  : 'No other roommate profiles are available right now.'
            : !hasFilterResults
            ? (_selectedFilter == 1 || _selectedFilter == 2
                  ? 'Users will appear here after they add their gender in Profile > Edit Profile. They are still available under All.'
                  : 'Try another filter to see more people.')
            : 'Refresh to check for new roommate profiles.',
        ctaLabel: !hasProfiles
            ? hasSeenProfiles && hasSavedLikes
                  ? 'View liked profiles'
                  : 'Refresh'
            : !hasFilterResults
            ? 'Show all profiles'
            : 'Refresh',
        onCta: !hasProfiles
            ? hasSeenProfiles && hasSavedLikes
                  ? _openLikedRoommates
                  : _loadRoommates
            : !hasFilterResults
            ? () => _applyFilter(0)
            : _loadRoommates,
      );
    }
    final remaining = _profiles.length - _currentIndex;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.topCenter,
            children: [
              if (remaining > 1)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: 24,
                  child: Opacity(
                    opacity: 0.6,
                    child: Transform.scale(
                      scale: 0.96,
                      child: IgnorePointer(
                        child: RoommateCardWidget(
                          roommate: _profiles[_currentIndex + 1],
                          onLike: () {},
                          onPass: () {},
                          isTop: false,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                bottom: 24,
                child: SlideTransition(
                  position: _isAnimatingOut
                      ? _exitAnimation
                      : const AlwaysStoppedAnimation(Offset.zero),
                  child: RoommateCardWidget(
                    key: ValueKey(_profiles[_currentIndex].id),
                    roommate: _profiles[_currentIndex],
                    onLike: () => _handleDecision(true),
                    onPass: () => _handleDecision(false),
                    onDetails: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoommateDetailScreen(
                          roommate: _profiles[_currentIndex],
                          showRequestAction: false,
                        ),
                      ),
                    ),
                    isTop: true,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} of ${_profiles.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoommateModel {
  final String id,
      name,
      profession,
      city,
      locality,
      imageUrl,
      semanticLabel,
      summary,
      budget,
      moveInDate,
      gender,
      foodPreference;
  final int age, compatibilityScore;
  final List<String> lifestyleTags;
  final List<String> matchReasons;
  final Map<String, dynamic> details;
  const RoommateModel({
    required this.id,
    required this.name,
    required this.age,
    required this.profession,
    required this.city,
    required this.locality,
    required this.imageUrl,
    required this.semanticLabel,
    required this.compatibilityScore,
    required this.summary,
    required this.lifestyleTags,
    required this.matchReasons,
    required this.budget,
    required this.moveInDate,
    required this.gender,
    required this.foodPreference,
    required this.details,
  });
  factory RoommateModel.fromApi(Map<String, dynamic> map) {
    String readText(dynamic value, {String fallback = 'Not specified'}) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? fallback : text;
    }

    final rawHobbies = map['hobbies'] ?? map['lifestyle_tags'];
    final hobbies = rawHobbies is List
        ? rawHobbies
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList()
        : rawHobbies is String
        ? rawHobbies
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList()
        : <String>[];
    final food = readText(map['food_preference'], fallback: '');
    final rawAge = map['age'];
    final age = rawAge is num
        ? rawAge.toInt()
        : int.tryParse(rawAge?.toString().trim() ?? '') ?? 0;
    final name = readText(map['name'], fallback: 'ApnaStay user');

    return RoommateModel(
      id: map['uid']?.toString() ?? '',
      name: name,
      age: age,
      profession: readText(map['occupation']),
      city: readText(map['city']),
      locality: readText(
        map['locality'],
        fallback: readText(
          map['localities'],
          fallback: readText(map['location']),
        ),
      ),
      imageUrl: readText(map['photo_url'], fallback: ''),
      semanticLabel: '$name profile photo',
      compatibilityScore: (map['compatibility_score'] is num
          ? (map['compatibility_score'] as num).round()
          : int.tryParse(map['compatibility_score']?.toString() ?? '') ?? 0),
      summary: readText(map['bio'], fallback: 'No bio added yet.'),
      lifestyleTags: [
        ...hobbies,
        if (food.isNotEmpty && food.toLowerCase() != 'no preference') food,
      ],
      matchReasons: (map['match_reasons'] is List)
          ? (map['match_reasons'] as List)
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .toList()
          : <String>[],
      budget: readText(map['budget']),
      moveInDate: readText(map['move_in_date']),
      gender: readText(map['gender']),
      foodPreference: food.isEmpty ? 'Not specified' : food,
      details: map,
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withAlpha(20),
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text('$count'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
