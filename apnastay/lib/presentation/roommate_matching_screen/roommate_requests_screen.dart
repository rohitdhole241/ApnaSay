import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import './roommate_detail_screen.dart';
import './roommate_matching_screen.dart';
import './roommate_pg_selection_screen.dart';

class RoommateRequestsScreen extends StatefulWidget {
  const RoommateRequestsScreen({super.key});

  @override
  State<RoommateRequestsScreen> createState() => _RoommateRequestsScreenState();
}

class _RoommateRequestsScreenState extends State<RoommateRequestsScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _mealBookings = [];
  List<Map<String, dynamic>> _roommatePgProposals = [];
  final Set<String> _responding = {};
  bool _isLoading = true;
  bool _isLoadingBookings = true;
  bool _isFetchingBookings = false;
  String? _error;
  String? _bookingError;
  Timer? _bookingRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadBookingUpdates(showLoading: true);
    _bookingRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadBookingUpdates(),
    );
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadRequests(),
      _loadBookingUpdates(showLoading: true),
    ]);
  }

  DateTime _bookingTime(Map<String, dynamic> booking) {
    final value = booking['updated_at'] ?? booking['created_at'];
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _loadBookingUpdates({bool showLoading = false}) async {
    if (_isFetchingBookings) return;
    _isFetchingBookings = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoadingBookings = true;
        _bookingError = null;
      });
    }
    try {
      final results = await Future.wait([
        _authService.getMyBookings(),
        _authService.getMyMealBookings(),
        _authService.getRoommatePgProposals(),
      ]);
      final bookings = results[0];
      final mealBookings = results[1];
      final proposals = results[2];
      bookings.sort((a, b) => _bookingTime(b).compareTo(_bookingTime(a)));
      mealBookings.sort((a, b) => _bookingTime(b).compareTo(_bookingTime(a)));
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _mealBookings = mealBookings;
        _roommatePgProposals = proposals;
        _isLoadingBookings = false;
        _bookingError = null;
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = error.message;
        _isLoadingBookings = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = 'Could not load your PG booking updates.';
        _isLoadingBookings = false;
      });
      debugPrint('Failed to load PG booking updates: $error');
    } finally {
      _isFetchingBookings = false;
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _authService.getRoommateRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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
        _error = 'Could not load roommate requests. Please try again.';
        _isLoading = false;
      });
      debugPrint('Failed to load roommate requests: $error');
    }
  }

  Future<void> _respond(String requestId, String decision) async {
    setState(() => _responding.add(requestId));
    try {
      await _authService.respondToRoommateRequest(
        requestId: requestId,
        decision: decision,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accept'
                ? 'Request accepted. You are now matched as potential roommates.'
                : 'Roommate request declined.',
          ),
        ),
      );
      await _loadRequests();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _responding.remove(requestId));
    }
  }

  void _openProfile(RoommateModel roommate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RoommateDetailScreen(roommate: roommate, showRequestAction: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      title: Text(
        'Notifications',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh notifications',
          onPressed: _isLoading || _isLoadingBookings ? null : _refreshAll,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'PG booking updates',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingBookings)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_bookingError != null)
            _inboxMessage(
              _bookingError!,
              action: TextButton(
                onPressed: () => _loadBookingUpdates(showLoading: true),
                child: const Text('Retry'),
              ),
            )
          else if (_bookings.isEmpty)
            _inboxMessage('Your PG booking decisions will appear here.')
          else
            ..._bookings.map(_bookingUpdateCard),
          const SizedBox(height: 24),
          Text(
            'Dabba service updates',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingBookings && _mealBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_mealBookings.isEmpty)
            _inboxMessage('Your meal provider responses will appear here.')
          else
            ..._mealBookings.map(_mealBookingUpdateCard),
          const SizedBox(height: 24),
          Text(
            'Roommate requests',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _inboxMessage(
              _error!,
              action: TextButton(
                onPressed: _loadRequests,
                child: const Text('Try again'),
              ),
            )
          else if (_requests.isEmpty)
            _inboxMessage(
              'New roommate requests and responses will appear here.',
            )
          else
            ..._requests.map(_requestCard),
          const SizedBox(height: 24),
          Text(
            'PG plans with roommates',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (_roommatePgProposals.isEmpty)
            _inboxMessage('PG proposals from your matched roommates will appear here.')
          else
            ..._roommatePgProposals.map(_roommatePgProposalCard),
        ],
      ),
    ),
  );

  Widget _inboxMessage(String message, {Widget? action}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Card(
      color: AppTheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
            ),
            if (action != null) action,
          ],
        ),
      ),
    ),
  );

  Widget _bookingUpdateCard(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final pgName = booking['pg_name']?.toString() ?? 'PG listing';
    final ownerName = booking['owner_name']?.toString() ?? 'the PG owner';
    final statusText = switch (status) {
      'accepted' => 'Your booking request was accepted by $ownerName.',
      'declined' => 'Your booking request was declined by $ownerName.',
      'cancelled' => 'You cancelled this booking request.',
      _ => 'Your request is waiting for $ownerName to respond.',
    };
    final (icon, color) = switch (status) {
      'accepted' => (Icons.check_circle_rounded, AppTheme.success),
      'declined' => (Icons.cancel_rounded, Colors.red.shade600),
      'cancelled' => (
        Icons.remove_circle_outline_rounded,
        AppTheme.onSurfaceMuted,
      ),
      _ => (Icons.hourglass_top_rounded, AppTheme.secondaryBrand),
    };
    final duration = booking['duration']?.toString();
    final amount = booking['amount']?.toString();

    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pgName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(statusText),
                  if (duration != null || amount != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (duration != null) duration,
                        if (amount != null) '₹$amount per month',
                      ].join(' · '),
                      style: GoogleFonts.outfit(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealBookingUpdateCard(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final providerName =
        booking['provider_name']?.toString() ?? 'Meal provider';
    final plan = booking['service_plan']?.toString() ?? 'Dabba service';
    final amount = booking['amount']?.toString();
    final statusText = switch (status) {
      'accepted' => '$providerName accepted your request.',
      'declined' => '$providerName declined your request.',
      _ => 'Your request is waiting for $providerName to respond.',
    };
    final (icon, color) = switch (status) {
      'accepted' => (Icons.check_circle_rounded, AppTheme.success),
      'declined' => (Icons.cancel_rounded, Colors.red),
      _ => (Icons.hourglass_top_rounded, AppTheme.secondaryBrand),
    };

    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(statusText),
                  const SizedBox(height: 5),
                  Text(
                    amount == null || amount.isEmpty
                        ? plan
                        : '$plan - ₹$amount',
                    style: GoogleFonts.outfit(
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 12,
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

  Future<void> _respondToPgProposal(String id, String decision) async {
    setState(() => _responding.add(id));
    try {
      await _authService.respondToRoommatePgProposal(id, decision);
      await _loadBookingUpdates(showLoading: true);
    } on AuthServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _responding.remove(id));
    }
  }

  Widget _roommatePgProposalCard(Map<String, dynamic> proposal) {
    final id = proposal['id']?.toString() ?? '';
    final status = proposal['status']?.toString() ?? '';
    final isRecipient = proposal['is_recipient'] == true;
    final canRespond = status == 'awaiting_roommate' && isRecipient && id.isNotEmpty;
    final roommateName = isRecipient
        ? proposal['proposer_name']?.toString() ?? 'Your roommate'
        : proposal['recipient_name']?.toString() ?? 'Your roommate';
    final statusText = switch (status) {
      'awaiting_roommate' => isRecipient
          ? '$roommateName proposed this PG for both of you.'
          : 'Waiting for $roommateName to agree to this PG.',
      'roommate_declined' => '$roommateName declined this PG proposal.',
      'sent_to_owner' => 'You both agreed. The PG owner is reviewing your request.',
      'pg_accepted' => 'The PG owner accepted your joint booking request.',
      'pg_declined' => 'The PG owner declined your joint booking request.',
      _ => 'Roommate PG request update.',
    };
    final icon = status == 'pg_accepted'
        ? Icons.check_circle_rounded
        : status == 'roommate_declined' || status == 'pg_declined'
            ? Icons.cancel_rounded
            : Icons.home_work_outlined;
    final color = status == 'pg_accepted'
        ? AppTheme.success
        : status == 'roommate_declined' || status == 'pg_declined'
            ? Colors.red
            : AppTheme.secondaryBrand;
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proposal['pg_name']?.toString() ?? 'PG listing', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(statusText),
                      const SizedBox(height: 5),
                      Text(
                        "${proposal['duration'] ?? ''} · ₹${proposal['amount'] ?? ''} per month",
                        style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canRespond) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _respondToPgProposal(id, 'declined'), child: const Text('Decline'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () => _respondToPgProposal(id, 'accepted'), child: const Text('Agree & send to owner'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final profileMap = request['roommate'];
    final profile = profileMap is Map
        ? RoommateModel.fromApi(Map<String, dynamic>.from(profileMap))
        : null;
    final requestId = request['request_id']?.toString() ?? '';
    final incoming = request['direction'] == 'incoming';
    final status = request['status']?.toString() ?? 'pending';
    final canRespond = incoming && status == 'pending' && requestId.isNotEmpty;
    final isResponding = _responding.contains(requestId);
    final name = profile?.name ?? 'ApnaStay user';
    final message = switch ((incoming, status)) {
      (true, 'pending') => 'Would like to be your roommate',
      (false, 'pending') => 'Waiting for their response',
      (_, 'accepted') => 'You both agreed to connect as roommates',
      (_, 'declined') => 'This request was declined',
      _ => 'Roommate request',
    };

    return Card(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _RequestAvatar(url: profile?.imageUrl ?? ''),
              title: Text(
                name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(message),
              trailing: status == 'accepted'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.success,
                    )
                  : null,
              onTap: profile == null ? null : () => _openProfile(profile),
            ),
            if (status == 'accepted' && requestId.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoommatePgSelectionScreen(
                        matchRequestId: requestId,
                        roommateName: name,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.home_work_rounded),
                  label: const Text('Choose a PG together'),
                ),
              ),
            ],
            if (canRespond) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isResponding
                          ? null
                          : () => _respond(requestId, 'decline'),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isResponding
                          ? null
                          : () => _respond(requestId, 'accept'),
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
}

class _RequestAvatar extends StatelessWidget {
  final String url;

  const _RequestAvatar({required this.url});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 28,
    backgroundColor: AppTheme.secondaryBrandLight,
    child: ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: url.trim().isEmpty
            ? const Icon(Icons.person_rounded, color: AppTheme.secondaryBrand)
            : Image.network(
                url,
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
