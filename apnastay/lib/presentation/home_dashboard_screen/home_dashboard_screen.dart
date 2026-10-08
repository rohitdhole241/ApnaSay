import 'dart:async';

import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_navigation.dart';
import '../pg_listings_screen/pg_listings_screen.dart';
import '../profile_screen/profile_screen.dart';
import '../roommate_matching_screen/roommate_requests_screen.dart';
import './widgets/feature_cards_row_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/home_hero_widget.dart';
import './widgets/home_section_header_widget.dart';
import './widgets/nearby_pg_strip_widget.dart';
import './widgets/popular_meals_strip_widget.dart';

// TODO: Replace with Bloc/Riverpod for production
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _navIndex = 0;
  bool _isSearchActive = false;
  String _userName = 'ApnaStay User';
  String _userPhotoUrl = '';
  int _bookingResponseCount = 0;
  final Map<String, String> _knownBookingStatuses = {};
  bool _hasLoadedBookingStatuses = false;
  Timer? _bookingStatusTimer;
  final AuthService _authService = AuthService();

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadBookingResponses();
    _bookingStatusTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadBookingResponses(),
    );
  }

  Future<void> _loadUserName() async {
    try {
      final profile = await _authService.getCurrentProfile();
      final name = profile['name']?.toString().trim();
      final photoUrl = profile['photo_url']?.toString().trim() ?? '';
      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        _userPhotoUrl = photoUrl;
      });
    } on AuthServiceException {
      // Keep fallback initials when the profile request is unavailable.
    }
  }

  Future<void> _loadBookingResponses() async {
    try {
      final results = await Future.wait([
        _authService.getMyBookings(),
        _authService.getMyMealBookings(),
      ]);
      final pgBookings = results[0];
      final mealBookings = results[1];
      final nextStatuses = <String, String>{};
      String? newResponse;

      void collectResponses(
        List<Map<String, dynamic>> bookings,
        String kind,
        String nameField,
      ) {
        for (final booking in bookings) {
          final id = booking['id']?.toString() ?? '';
          final status = booking['status']?.toString() ?? 'pending';
          if (id.isEmpty) continue;
          final key = '$kind:$id';
          nextStatuses[key] = status;
          if (_hasLoadedBookingStatuses &&
              _knownBookingStatuses[key] == 'pending' &&
              (status == 'accepted' || status == 'declined')) {
            final name =
                booking[nameField]?.toString() ??
                (kind == 'meal' ? 'the meal provider' : 'your PG');
            newResponse = kind == 'meal'
                ? status == 'accepted'
                      ? '$name accepted your dabba service request.'
                      : '$name declined your dabba service request.'
                : status == 'accepted'
                ? 'Your booking request for $name was accepted.'
                : 'Your booking request for $name was declined.';
          }
        }
      }

      collectResponses(pgBookings, 'pg', 'pg_name');
      collectResponses(mealBookings, 'meal', 'provider_name');
      if (!mounted) return;
      setState(() {
        _knownBookingStatuses
          ..clear()
          ..addAll(nextStatuses);
        _hasLoadedBookingStatuses = true;
        _bookingResponseCount = [...pgBookings, ...mealBookings]
            .where(
              (booking) =>
                  booking['status'] == 'accepted' ||
                  booking['status'] == 'declined',
            )
            .length;
      });
      if (newResponse != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(newResponse!)));
      }
    } on AuthServiceException {
      // Keep showing the last known count if the API is temporarily unavailable.
    }
  }

  @override
  void dispose() {
    _bookingStatusTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_navIndex == 0)
              HomeAppBarWidget(
                isSearchActive: _isSearchActive,
                userName: _userName,
                userPhotoUrl: _userPhotoUrl,
                notificationCount: _bookingResponseCount,
                onSearchToggle: () =>
                    setState(() => _isSearchActive = !_isSearchActive),
                onProfileTap: () => _onNavTap(3),
                onNotificationTap: () => _onNavTap(2),
              ),
            Expanded(child: _buildBody(isTablet)),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildBody(bool isTablet) {
    Widget homeContent = isTablet ? _buildTabletLayout() : _buildPhoneLayout();

    return IndexedStack(
      index: _navIndex,
      children: [
        homeContent,
        const PgListingsScreen(), // Explore
        const RoommateRequestsScreen(), // Activity
        const ProfileScreen(), // Profile
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const HomeHeroWidget(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HomeSectionHeaderWidget(
                  title: 'What are you looking for?',
                  subtitle: 'Tap to explore each service',
                ),
              ),
              const SizedBox(height: 12),
              const FeatureCardsRowWidget(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomeSectionHeaderWidget(
                  title: 'Near You',
                  subtitle: 'PGs within 5 km',
                  actionLabel: 'See all',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.pgListingsScreen),
                ),
              ),
              const SizedBox(height: 12),
              const NearbyPgStripWidget(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomeSectionHeaderWidget(
                  title: 'Popular Meals Today',
                  subtitle: 'Home-cooked dabba services',
                  actionLabel: 'Browse all',
                  onAction: () => Navigator.pushNamed(
                    context,
                    AppRoutes.dabbaServiceScreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const PopularMealsStripWidget(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 12, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeroWidget(),
                const SizedBox(height: 24),
                const HomeSectionHeaderWidget(
                  title: 'Near You',
                  subtitle: 'PGs within 5 km',
                  actionLabel: 'See all',
                ),
                const SizedBox(height: 12),
                const NearbyPgStripWidget(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 12, right: 24, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeSectionHeaderWidget(
                  title: 'Services',
                  subtitle: 'Explore each feature',
                ),
                const SizedBox(height: 12),
                const FeatureCardsRowWidget(vertical: true),
                const SizedBox(height: 24),
                const HomeSectionHeaderWidget(
                  title: 'Popular Meals',
                  subtitle: 'Today\'s dabba picks',
                ),
                const SizedBox(height: 12),
                const PopularMealsStripWidget(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
