import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile_screen/profile_screen.dart';

class MealProviderDashboardScreen extends StatefulWidget {
  const MealProviderDashboardScreen({super.key});

  @override
  State<MealProviderDashboardScreen> createState() =>
      _MealProviderDashboardScreenState();
}

class _MealProviderDashboardScreenState
    extends State<MealProviderDashboardScreen> {
  int _navIndex = 0;
  final AuthService _authService = AuthService();
  String _providerName = 'Meal Provider';
  String _providerPhotoUrl = '';
  List<Map<String, dynamic>> _mealRequests = [];
  final Set<String> _respondingTo = {};
  bool _isLoadingRequests = true;
  bool _isFetchingRequests = false;
  String? _requestError;
  Timer? _requestRefreshTimer;

  int get _pendingRequestCount =>
      _mealRequests.where((request) => request['status'] == 'pending').length;

  @override
  void initState() {
    super.initState();
    _loadProvider();
    _loadRequests(showLoading: true);
    _requestRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadRequests(),
    );
  }

  @override
  void dispose() {
    _requestRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProvider() async {
    try {
      final profile = await _authService.getCurrentProfile();
      final providerName = profile['provider_name']?.toString().trim();
      final providerPhoto = profile['provider_photo_url']?.toString().trim();
      final userPhoto = profile['photo_url']?.toString().trim();
      if (!mounted) return;
      setState(() {
        _providerName = providerName?.isNotEmpty == true
            ? providerName!
            : profile['name']?.toString() ?? 'Meal Provider';
        _providerPhotoUrl = providerPhoto?.isNotEmpty == true
            ? providerPhoto!
            : userPhoto ?? '';
      });
    } on AuthServiceException {
      // Keep the fallback dashboard name when the profile request is unavailable.
    }
  }

  DateTime _requestTime(Map<String, dynamic> request) =>
      DateTime.tryParse(
        (request['updated_at'] ?? request['created_at'])?.toString() ?? '',
      ) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _loadRequests({bool showLoading = false}) async {
    if (_isFetchingRequests) return;
    _isFetchingRequests = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoadingRequests = true;
        _requestError = null;
      });
    }
    try {
      final requests = await _authService.getProviderMealBookings();
      requests.sort((a, b) => _requestTime(b).compareTo(_requestTime(a)));
      if (!mounted) return;
      setState(() {
        _mealRequests = requests;
        _isLoadingRequests = false;
        _requestError = null;
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = error.message;
        _isLoadingRequests = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = 'Could not load meal service requests.';
        _isLoadingRequests = false;
      });
      debugPrint('Failed to load meal service requests: $error');
    } finally {
      _isFetchingRequests = false;
    }
  }

  Future<void> _respondToRequest(String bookingId, String status) async {
    if (bookingId.isEmpty) return;
    setState(() => _respondingTo.add(bookingId));
    try {
      await _authService.respondToMealBooking(
        bookingId: bookingId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Meal service request accepted.'
                : 'Meal service request declined.',
          ),
        ),
      );
      await _loadRequests(showLoading: true);
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _respondingTo.remove(bookingId));
    }
  }

  Widget _avatarInitials() => Center(
    child: Text(
      _initials(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.tertiaryBrand,
      ),
    ),
  );

  String _initials() {
    final parts = _providerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MP';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, $_providerName',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _pendingRequestCount == 0
                ? 'Meal service requests'
                : '$_pendingRequestCount pending meal requests',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_pendingRequestCount > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      child: Text(
                        _pendingRequestCount > 9
                            ? '9+'
                            : '$_pendingRequestCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _navIndex = 2);
              _loadRequests(showLoading: true);
            },
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(isMealProvider: true),
                ),
              );
              if (mounted) _loadProvider();
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryBrandLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _providerPhotoUrl.isEmpty
                    ? _avatarInitials()
                    : CachedNetworkImage(
                        imageUrl: _providerPhotoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _avatarInitials(),
                        errorWidget: (_, _, _) => _avatarInitials(),
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
          if (i == 2) _loadRequests(showLoading: true);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.tertiaryBrand,
        unselectedItemColor: AppTheme.onSurfaceMuted,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Logistics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meals',
          ),
          BottomNavigationBarItem(
            icon: _pendingRequestCount > 0
                ? Badge(
                    label: Text('$_pendingRequestCount'),
                    child: const Icon(Icons.inbox_outlined),
                  )
                : const Icon(Icons.inbox_outlined),
            label: 'Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return _buildLogistics();
      case 1:
        return const Center(child: Text('Manage your daily meal menu'));
      case 2:
        return _buildRequests();
      default:
        return const SizedBox();
    }
  }

  Widget _buildRequests() {
    return RefreshIndicator(
      onRefresh: () => _loadRequests(showLoading: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Meal service requests',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review each customer before accepting or declining.',
            style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 14),
          if (_isLoadingRequests && _mealRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_requestError != null && _mealRequests.isEmpty)
            Card(
              child: ListTile(
                title: Text(_requestError!),
                trailing: TextButton(
                  onPressed: () => _loadRequests(showLoading: true),
                  child: const Text('Retry'),
                ),
              ),
            )
          else if (_mealRequests.isEmpty)
            Card(
              color: AppTheme.surface,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('New dabba service requests will appear here.'),
              ),
            )
          else
            ..._mealRequests.map(_requestCard),
          if (_requestError != null && _mealRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Could not refresh requests: $_requestError',
                style: GoogleFonts.outfit(color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final rawProfile = request['requester'];
    final requester = rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : <String, dynamic>{};
    final requestId = request['id']?.toString() ?? '';
    final status = request['status']?.toString() ?? 'pending';
    final isPending = status == 'pending';
    final isResponding = _respondingTo.contains(requestId);
    final name = _text(
      requester['name'],
      request['user_name']?.toString() ?? 'ApnaStay user',
    );
    final photoUrl = _text(
      requester['photo_url'],
      request['user_photo_url']?.toString() ?? '',
    );

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _requesterAvatar(photoUrl, radius: 25),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isPending
                            ? 'Waiting for your decision'
                            : 'Request $status',
                        style: GoogleFonts.outfit(
                          color: isPending
                              ? AppTheme.secondaryBrand
                              : _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.restaurant_rounded, color: AppTheme.tertiaryBrand),
              ],
            ),
            const SizedBox(height: 12),
            _requestDetailLine('Plan', request['service_plan']),
            _requestDetailLine('Amount', _amount(request['amount'])),
            _requestDetailLine('Delivery address', request['delivery_address']),
            if (_text(request['notes']).isNotEmpty)
              _requestDetailLine('Notes', request['notes']),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showRequesterProfile(request, requester),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('View customer profile'),
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isResponding
                          ? null
                          : () => _respondToRequest(requestId, 'declined'),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: isResponding
                          ? null
                          : () => _respondToRequest(requestId, 'accepted'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.tertiaryBrand,
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

  void _showRequesterProfile(
    Map<String, dynamic> request,
    Map<String, dynamic> requester,
  ) {
    final name = _text(
      requester['name'],
      request['user_name']?.toString() ?? 'ApnaStay user',
    );
    final fields = <(String, dynamic)>[
      ('Email', requester['email']),
      ('Phone', requester['phone']),
      ('Age', requester['age']),
      ('Gender', requester['gender']),
      ('About', requester['bio']),
      ('City', requester['city']),
      ('Locality', requester['locality']),
      ('Occupation', requester['occupation']),
      ('College / company', requester['college_company']),
      ('Course / job', requester['course_job']),
      ('Food preference', requester['food_preference']),
      ('Food habits', requester['food_habit']),
      ('Interests', requester['hobbies']),
      ('Delivery address', request['delivery_address']),
      ('Service plan', request['service_plan']),
      ('Request amount', _amount(request['amount'])),
      ('Customer notes', request['notes']),
    ];
    final photoUrl = _text(
      requester['photo_url'],
      request['user_photo_url']?.toString() ?? '',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  _requesterAvatar(photoUrl, radius: 27),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(
                    'Customer profile and dabba request',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fields
                      .where((field) => _text(field.$2).isNotEmpty)
                      .map((field) => _requestDetailLine(field.$1, field.$2)),
                ],
              ),
            ),
            if (request['status'] == 'pending')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _respondingTo.contains(request['id']?.toString())
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _respondToRequest(
                                  request['id']?.toString() ?? '',
                                  'declined',
                                );
                              },
                        child: const Text('Decline request'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _respondingTo.contains(request['id']?.toString())
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _respondToRequest(
                                  request['id']?.toString() ?? '',
                                  'accepted',
                                );
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.tertiaryBrand,
                        ),
                        child: const Text('Accept request'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _requesterAvatar(String photoUrl, {required double radius}) {
    const fallback = Icon(
      Icons.person_outline_rounded,
      color: AppTheme.tertiaryBrand,
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.tertiaryBrandLight,
      child: photoUrl.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                photoUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }

  Widget _requestDetailLine(String label, dynamic value) {
    final text = _text(value);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _amount(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? '' : '\u20B9$text';
  }

  Color _statusColor(String status) => switch (status) {
    'accepted' => AppTheme.success,
    'declined' => Colors.red.shade600,
    _ => AppTheme.onSurfaceMuted,
  };

  Widget _buildLogistics() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Logistics Overview',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildStatCard('Active Subs', '128', Icons.people)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Earnings',
                '\u20B9 1.2L',
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Scheduled Meals Today',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMealRow('Lunch (Veg)', '85 portions'),
        const SizedBox(height: 8),
        _buildMealRow('Lunch (Non-Veg)', '43 portions'),
        const SizedBox(height: 8),
        _buildMealRow('Dinner (Mixed)', '110 portions'),
      ],
    );
  }

  Widget _buildMealRow(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.tertiaryBrand,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          Icon(icon, color: AppTheme.tertiaryBrand, size: 28),
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
