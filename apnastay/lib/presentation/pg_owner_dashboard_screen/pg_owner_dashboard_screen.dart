import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile_screen/profile_screen.dart';

class PgOwnerDashboardScreen extends StatefulWidget {
  const PgOwnerDashboardScreen({super.key});

  @override
  State<PgOwnerDashboardScreen> createState() => _PgOwnerDashboardScreenState();
}

class _PgOwnerDashboardScreenState extends State<PgOwnerDashboardScreen> {
  int _navIndex = 0;
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _listings = [];
  String _ownerName = 'Owner';
  String _ownerPhotoUrl = '';
  bool _isLoadingListings = true;
  List<Map<String, dynamic>> _bookingRequests = [];
  bool _isLoadingBookings = true;
  bool _isFetchingBookings = false;
  bool _hasLoadedBookings = false;
  String? _bookingError;
  final Set<String> _respondingBookingIds = {};
  Timer? _bookingRefreshTimer;

  int get _pendingBookingCount => _bookingRequests
      .where((booking) => booking['status'] == 'pending')
      .length;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _bookingRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadBookingRequests(),
    );
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        _authService.getCurrentProfile(),
        _authService.getMyPgs(),
      ]);
      if (!mounted) return;
      final profile = results[0] as Map<String, dynamic>;
      setState(() {
        _ownerName = profile['name']?.toString() ?? 'Owner';
        _ownerPhotoUrl =
            (profile['owner_photo_url'] ?? profile['photo_url'])
                ?.toString()
                .trim() ??
            '';
        _listings = results[1] as List<Map<String, dynamic>>;
        _isLoadingListings = false;
      });
      _loadBookingRequests();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingListings = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, $_ownerName',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Booking requests',
            onPressed: _openBookingRequests,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_pendingBookingCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _pendingBookingCount > 9
                            ? '9+'
                            : '$_pendingBookingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openOwnerProfile,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBrandLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ownerPhotoUrl.isEmpty
                    ? Center(
                        child: Text(
                          _ownerInitials(),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryBrand,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: _ownerPhotoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            _ownerInitials(),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryBrand,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 2) _loadBookingRequests(showLoading: true);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.secondaryBrand,
        unselectedItemColor: AppTheme.onSurfaceMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Logistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            label: 'My PGs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
        ],
      ),
    );
  }

  Future<void> _openOwnerProfile() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen(isOwner: true)),
      );
      if (mounted) _loadDashboard();
    } on AuthServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  String _ownerInitials() {
    final parts = _ownerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return _buildLogistics();
      case 1:
        return _buildListings();
      case 2:
        return _buildBookingRequests();
      case 3:
        return const Center(child: Text('Chat with your tenants'));
      default:
        return const SizedBox();
    }
  }

  void _openBookingRequests() {
    setState(() => _navIndex = 2);
    _loadBookingRequests(showLoading: true);
  }

  Future<void> _loadBookingRequests({bool showLoading = false}) async {
    if (_isFetchingBookings) return;
    _isFetchingBookings = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoadingBookings = true;
        _bookingError = null;
      });
    }
    try {
      final requests = await _authService.getOwnerBookings();
      requests.sort((a, b) {
        final aPending = a['status'] == 'pending';
        final bPending = b['status'] == 'pending';
        return aPending == bPending ? 0 : (aPending ? -1 : 1);
      });
      final newPendingCount = requests
          .where((booking) => booking['status'] == 'pending')
          .length;
      final gotNewRequest =
          _hasLoadedBookings && newPendingCount > _pendingBookingCount;
      if (!mounted) return;
      setState(() {
        _bookingRequests = requests;
        _isLoadingBookings = false;
        _bookingError = null;
        _hasLoadedBookings = true;
      });
      if (gotNewRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new PG booking request has arrived.'),
          ),
        );
      }
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingBookings = false;
        _bookingError = error.message;
      });
    } finally {
      _isFetchingBookings = false;
    }
  }

  Widget _buildBookingRequests() {
    if (_isLoadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_bookingError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _loadBookingRequests(showLoading: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final pendingCount = _pendingBookingCount;
    return RefreshIndicator(
      onRefresh: () => _loadBookingRequests(showLoading: true),
      child: _bookingRequests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 90),
                Icon(
                  Icons.notifications_none,
                  size: 52,
                  color: AppTheme.onSurfaceMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'No booking requests yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Booking Requests',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$pendingCount waiting for your response'),
                const SizedBox(height: 16),
                ..._bookingRequests.map(_bookingRequestCard),
              ],
            ),
    );
  }

  Widget _bookingRequestCard(Map<String, dynamic> booking) {
    final id = booking['id']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';
    final isPending = status == 'pending';
    final isResponding = _respondingBookingIds.contains(id);
    final requester = booking['requester'] is Map
        ? Map<String, dynamic>.from(booking['requester'] as Map)
        : <String, dynamic>{};
    final requesterName =
        _profileValue(requester['name']) ??
        booking['user_name']?.toString() ??
        'ApnaStay user';
    final requesterPhotoUrl =
        (_profileValue(requester['photo_url']) ??
                booking['user_photo_url']?.toString() ??
                '')
            .trim();
    final requesterEmail =
        _profileValue(requester['email']) ??
        _profileValue(booking['user_email']);
    final statusLabel = switch (status) {
      'accepted' => 'Accepted',
      'declined' => 'Declined',
      'cancelled' => 'Cancelled',
      _ => 'Waiting for your response',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.secondaryBrandLight,
                  backgroundImage: requesterPhotoUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(requesterPhotoUrl),
                  child: requesterPhotoUrl.isEmpty
                      ? const Icon(
                          Icons.person_outline,
                          color: AppTheme.secondaryBrand,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(booking['pg_name']?.toString() ?? 'Your PG'),
                    ],
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: status == 'accepted'
                        ? Colors.green.shade700
                        : status == 'declined' || status == 'cancelled'
                        ? AppTheme.onSurfaceMuted
                        : AppTheme.secondaryBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${booking['duration'] ?? 'Duration not specified'} · ₹${booking['amount'] ?? '-'} per month',
              style: GoogleFonts.outfit(color: AppTheme.onSurfaceMedium),
            ),
            if ((booking['move_in_date']?.toString() ?? '').isNotEmpty)
              Text('Preferred move-in: ${booking['move_in_date']}'),
            if (requesterEmail != null) Text(requesterEmail),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showApplicantDetails(booking),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('View applicant details'),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isResponding
                          ? null
                          : () => _respondToBooking(id, 'declined'),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isResponding
                          ? null
                          : () => _respondToBooking(id, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBrand,
                        foregroundColor: Colors.white,
                      ),
                      child: isResponding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _profileValue(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final items = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return items.isEmpty ? null : items.join(', ');
    }
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return null;
    return text;
  }

  Widget _applicantDetail(String label, dynamic value) {
    final displayValue = _profileValue(value);
    if (displayValue == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppTheme.onSurfaceMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(displayValue),
        ],
      ),
    );
  }

  void _showApplicantDetails(Map<String, dynamic> booking) {
    final requester = booking['requester'] is Map
        ? Map<String, dynamic>.from(booking['requester'] as Map)
        : <String, dynamic>{};
    final name =
        _profileValue(requester['name']) ??
        booking['user_name']?.toString() ??
        'ApnaStay user';
    final photoUrl =
        (_profileValue(requester['photo_url']) ??
                booking['user_photo_url']?.toString() ??
                '')
            .trim();
    final bookingId = booking['id']?.toString() ?? '';
    final pending = booking['status']?.toString() == 'pending';
    final coApplicants = (booking['co_applicants'] as List?)?.whereType<Map>().map((profile) => Map<String, dynamic>.from(profile)).toList() ?? <Map<String, dynamic>>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.secondaryBrandLight,
                    backgroundImage: photoUrl.isEmpty
                        ? null
                        : CachedNetworkImageProvider(photoUrl),
                    child: photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline,
                            size: 34,
                            color: AppTheme.secondaryBrand,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Applicant for ${booking['pg_name'] ?? 'your PG'}',
                          style: TextStyle(color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close applicant details',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Booking request',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _applicantDetail('Requested duration', booking['duration']),
              _applicantDetail('Monthly amount', booking['amount']),
              _applicantDetail('Preferred move-in', booking['move_in_date']),
              _applicantDetail('Requested room type', booking['room_type']),
              const Divider(height: 24),
              Text(
                'Contact and profile',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _applicantDetail(
                'Email',
                requester['email'] ?? booking['user_email'],
              ),
              _applicantDetail('Phone', requester['phone']),
              _applicantDetail('Age', requester['age']),
              _applicantDetail('Gender', requester['gender']),
              _applicantDetail('About', requester['bio']),
              _applicantDetail('City', requester['city']),
              _applicantDetail(
                'Locality preferences',
                requester['locality'] ?? requester['localities'],
              ),
              _applicantDetail('Occupation', requester['occupation']),
              _applicantDetail(
                'College or company',
                requester['college_company'],
              ),
              _applicantDetail('Course or job', requester['course_job']),
              _applicantDetail('Monthly budget', requester['budget']),
              _applicantDetail('Move-in date', requester['move_in_date']),
              _applicantDetail('Room preference', requester['room_type']),
              _applicantDetail('PG preference', requester['pg_type']),
              _applicantDetail('Food preference', requester['food_preference']),
              _applicantDetail('Food habits', requester['food_habit']),
              _applicantDetail(
                'Cleanliness',
                requester['cleanliness_level'] ?? requester['cleanliness'],
              ),
              _applicantDetail(
                'Cleaning routine',
                requester['cleaning_frequency'],
              ),
              _applicantDetail('Sleep schedule', requester['sleep_schedule']),
              _applicantDetail('Wake-up time', requester['wake_up_time']),
              _applicantDetail(
                'Noise preference',
                requester['noise_preference'],
              ),
              _applicantDetail('Social lifestyle', requester['social_level']),
              _applicantDetail(
                'Weekend lifestyle',
                requester['weekend_lifestyle'],
              ),
              _applicantDetail(
                'Study/work environment',
                requester['study_environment'],
              ),
              _applicantDetail('Interests', requester['hobbies']),
              _applicantDetail(
                'Preferred personality',
                requester['preferred_personality'],
              ),
              _applicantDetail(
                'Important compatibility factors',
                requester['compatibility_factors'],
              ),
              for (final coApplicant in coApplicants) ...[
                const Divider(height: 30),
                Text('Matched roommate applicant', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.secondaryBrandLight,
                    backgroundImage: (coApplicant['photo_url']?.toString().isNotEmpty ?? false) ? CachedNetworkImageProvider(coApplicant['photo_url'].toString()) : null,
                    child: (coApplicant['photo_url']?.toString().isNotEmpty ?? false) ? null : const Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(coApplicant['name']?.toString() ?? 'Roommate applicant', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
                ]),
                _applicantDetail('Email', coApplicant['email']),
                _applicantDetail('Phone', coApplicant['phone']),
                _applicantDetail('Age', coApplicant['age']),
                _applicantDetail('Gender', coApplicant['gender']),
                _applicantDetail('About', coApplicant['bio']),
                _applicantDetail('City', coApplicant['city']),
                _applicantDetail('Locality', coApplicant['locality'] ?? coApplicant['localities']),
                _applicantDetail('Occupation', coApplicant['occupation']),
                _applicantDetail('College or company', coApplicant['college_company']),
                _applicantDetail('Course or job', coApplicant['course_job']),
                _applicantDetail('Monthly budget', coApplicant['budget']),
                _applicantDetail('Move-in date', coApplicant['move_in_date']),
                _applicantDetail('Room preference', coApplicant['room_type']),
                _applicantDetail('PG preference', coApplicant['pg_type']),
                _applicantDetail('Food preference', coApplicant['food_preference']),
                _applicantDetail('Food habits', coApplicant['food_habit']),
                _applicantDetail('Cleanliness', coApplicant['cleanliness_level'] ?? coApplicant['cleanliness']),
                _applicantDetail('Cleaning routine', coApplicant['cleaning_frequency']),
                _applicantDetail('Sleep schedule', coApplicant['sleep_schedule']),
                _applicantDetail('Wake-up time', coApplicant['wake_up_time']),
                _applicantDetail('Noise preference', coApplicant['noise_preference']),
                _applicantDetail('Social lifestyle', coApplicant['social_level']),
                _applicantDetail('Weekend lifestyle', coApplicant['weekend_lifestyle']),
                _applicantDetail('Study/work environment', coApplicant['study_environment']),
                _applicantDetail('Interests', coApplicant['hobbies']),
                _applicantDetail('Preferred personality', coApplicant['preferred_personality']),
                _applicantDetail('Compatibility factors', coApplicant['compatibility_factors']),
              ],
              if (pending) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _respondToBooking(bookingId, 'declined');
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _respondToBooking(bookingId, 'accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryBrand,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept request'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respondToBooking(String id, String status) async {
    setState(() => _respondingBookingIds.add(id));
    try {
      await _authService.respondToBooking(bookingId: id, status: status);
      if (mounted) {
        setState(() {
          for (final booking in _bookingRequests) {
            if (booking['id']?.toString() == id) booking['status'] = status;
          }
        });
      }
      await _loadBookingRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Booking request accepted.'
                  : 'Booking request declined.',
            ),
          ),
        );
      }
    } on AuthServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _respondingBookingIds.remove(id));
    }
  }

  Widget _buildListings() {
    if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My PG Listings',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateListing,
              icon: const Icon(Icons.add),
              label: const Text('Add PG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBrand,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_listings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Create your first PG listing to get started.'),
            ),
          ),
        ..._listings.map(_listingCard),
      ],
    );
  }

  Widget _listingCard(Map<String, dynamic> listing) {
    final imageUrls = <String>[];
    final listedImages = listing['image_urls'] as List?;
    if (listedImages != null) {
      for (final item in listedImages) {
        final url = item?.toString().trim() ?? '';
        if ((url.startsWith('https://') || url.startsWith('http://')) &&
            !imageUrls.contains(url)) {
          imageUrls.add(url);
        }
      }
    }
    final primaryImage = listing['image_url']?.toString().trim() ?? '';
    if ((primaryImage.startsWith('https://') ||
            primaryImage.startsWith('http://')) &&
        !imageUrls.contains(primaryImage)) {
      imageUrls.insert(0, primaryImage);
    }
    final videoUrls =
        (listing['video_urls'] as List?)
            ?.whereType<String>()
            .map((url) => url.trim())
            .where(
              (url) => url.startsWith('https://') || url.startsWith('http://'),
            )
            .toList() ??
        <String>[];
    final photo = imageUrls.isEmpty ? '' : imageUrls.first;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo.isNotEmpty)
                  Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _pgPhotoPlaceholder(),
                  )
                else
                  _pgPhotoPlaceholder(),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(170),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${imageUrls.length} photo${imageUrls.length == 1 ? '' : 's'}  ·  ${videoUrls.length} video${videoUrls.length == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing['name']?.toString() ?? 'Unnamed PG',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${listing['locality'] ?? ''}, ${listing['city'] ?? ''}',
                      ),
                      Text(
                        '${imageUrls.length} PG photos uploaded · ${videoUrls.length} video tours',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                      Text(
                        'Rent: ₹${listing['price'] ?? '-'} | Beds: ${listing['available_beds'] ?? '-'}',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit PG',
                  onPressed: () => _editListing(listing),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pgPhotoPlaceholder() => Container(
    color: AppTheme.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(
      Icons.home_work_outlined,
      size: 42,
      color: AppTheme.onSurfaceMuted,
    ),
  );

  Future<void> _editListing(Map<String, dynamic> listing) async {
    final priceController = TextEditingController(
      text: listing['price']?.toString() ?? '',
    );
    final bedsController = TextEditingController(
      text: listing['available_beds']?.toString() ?? '',
    );
    final available = listing['is_available'] == true;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${listing['name'] ?? 'PG'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly rent'),
            ),
            TextField(
              controller: bedsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Available beds'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'price': double.tryParse(priceController.text),
              'available_beds': int.tryParse(bedsController.text),
              'is_available': available,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    priceController.dispose();
    bedsController.dispose();
    if (result == null || listing['id'] == null || !mounted) return;
    try {
      await _authService.updatePg(listing['id'].toString(), result);
      await _loadDashboard();
    } on AuthServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showCreateListing() async {
    final nameController = TextEditingController();
    final localityController = TextEditingController();
    final cityController = TextEditingController(text: 'Mumbai');
    final priceController = TextEditingController();
    final selectedPhotos = <XFile>[];
    XFile? selectedVideo;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickPhotos() async {
            final files = await ImagePicker().pickMultiImage(imageQuality: 80);
            if (files.isNotEmpty) {
              setSheetState(() => selectedPhotos.addAll(files));
            }
          }

          Future<void> pickVideo() async {
            final file = await ImagePicker().pickVideo(
              source: ImageSource.gallery,
            );
            if (file != null) setSheetState(() => selectedVideo = file);
          }

          Future<void> saveListing() async {
            if (nameController.text.trim().isEmpty ||
                localityController.text.trim().isEmpty ||
                priceController.text.trim().isEmpty ||
                selectedPhotos.isEmpty) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Add name, locality, price and at least one photo.',
                  ),
                ),
              );
              return;
            }

            setSheetState(() => isSaving = true);
            try {
              final imageUrls = <String>[];
              for (final photo in selectedPhotos) {
                imageUrls.add(
                  await _authService.uploadImage(
                    bytes: await photo.readAsBytes(),
                    filename: photo.name,
                    category: 'pg_room',
                  ),
                );
              }

              final videoUrls = <String>[];
              if (selectedVideo != null) {
                videoUrls.add(
                  await _authService.uploadVideo(
                    bytes: await selectedVideo!.readAsBytes(),
                    filename: selectedVideo!.name,
                  ),
                );
              }

              await _authService.createPg({
                'name': nameController.text.trim(),
                'locality': localityController.text.trim(),
                'city': cityController.text.trim(),
                'price': double.parse(priceController.text.trim()),
                'image_url': imageUrls.first,
                'image_urls': imageUrls,
                'video_urls': videoUrls,
                'is_available': true,
              });

              if (!mounted || !sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PG listing created successfully.'),
                ),
              );
            } on AuthServiceException catch (error) {
              if (!sheetContext.mounted) return;
              setSheetState(() => isSaving = false);
              ScaffoldMessenger.of(
                sheetContext,
              ).showSnackBar(SnackBar(content: Text(error.message)));
            } on FormatException {
              if (!sheetContext.mounted) return;
              setSheetState(() => isSaving = false);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(content: Text('Price must be a valid number.')),
              );
            } catch (error) {
              if (!sheetContext.mounted) return;
              setSheetState(() => isSaving = false);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text('Could not save the PG listing: $error'),
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create PG Listing',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _listingField(
                    'PG name',
                    'Enter the name of your PG',
                    nameController,
                  ),
                  _listingField(
                    'Locality',
                    'Enter the area or locality',
                    localityController,
                  ),
                  _listingField('City', 'Enter the city', cityController),
                  _listingField(
                    'Monthly rent',
                    'Enter monthly rent',
                    priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _listingUpload(
                    'PG photos',
                    selectedPhotos.isEmpty
                        ? 'Select one or more photos'
                        : '${selectedPhotos.length} photos ready to upload',
                    pickPhotos,
                    Icons.photo_library_outlined,
                  ),
                  _listingUpload(
                    'PG video',
                    selectedVideo == null
                        ? 'Select a walkthrough video'
                        : '1 video ready to upload',
                    pickVideo,
                    Icons.video_library_outlined,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSaving ? null : saveListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBrand,
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Save PG Listing'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    nameController.dispose();
    localityController.dispose();
    cityController.dispose();
    priceController.dispose();
    if (mounted) _loadDashboard();
  }

  Widget _listingField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _listingUpload(
    String label,
    String text,
    VoidCallback onPressed,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Align(alignment: Alignment.centerLeft, child: Text(text)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.centerLeft,
            foregroundColor: AppTheme.secondaryBrand,
            side: const BorderSide(color: AppTheme.secondaryBrand),
          ),
        ),
      ],
    ),
  );

  Widget _buildLogistics() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Overview',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildStatCard('Total PGs', '3', Icons.business)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Active Tenants', '45', Icons.people),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Occupancy Rate', '92%', Icons.pie_chart),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Monthly Rev',
                '₹ 4.5L',
                Icons.currency_rupee,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryBrand, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
