import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import './roommate_matching_screen.dart';

class RoommateDetailScreen extends StatefulWidget {
  final RoommateModel roommate;
  final bool showRequestAction;

  const RoommateDetailScreen({
    super.key,
    required this.roommate,
    this.showRequestAction = true,
  });

  @override
  State<RoommateDetailScreen> createState() => _RoommateDetailScreenState();
}

class _RoommateDetailScreenState extends State<RoommateDetailScreen> {
  final AuthService _authService = AuthService();
  String? _requestStatus;
  bool _checkingRequest = true;
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadRequestStatus();
  }

  Future<void> _loadRequestStatus() async {
    if (!widget.showRequestAction || widget.roommate.id.isEmpty) {
      _checkingRequest = false;
      return;
    }
    try {
      final status = await _authService.getRoommateRequestStatus(
        targetUid: widget.roommate.id,
      );
      if (mounted) setState(() => _requestStatus = status);
    } on AuthServiceException catch (error) {
      debugPrint('Could not load roommate request status: ${error.message}');
    } finally {
      if (mounted) setState(() => _checkingRequest = false);
    }
  }

  Future<void> _sendRoommateRequest() async {
    setState(() => _sendingRequest = true);
    try {
      final response = await _authService.createRoommateRequest(
        targetUid: widget.roommate.id,
      );
      if (!mounted) return;
      setState(() => _requestStatus = response['status']?.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent. They can respond in Roommate Requests.'),
        ),
      );
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roommate = widget.roommate;
    final details = roommate.details;
    final sections = <Map<String, String>>[
      {'Bio': roommate.summary},
      {'Occupation': roommate.profession},
      {'Gender': roommate.gender},
      {'City': roommate.city},
      {'Locality': roommate.locality},
      {'Budget': roommate.budget},
      {'Move-in date': roommate.moveInDate},
      {
        'Food preference':
            details['food_preference']?.toString() ?? 'Not specified',
      },
      {
        'Cleanliness': _displayList(
          details['cleanliness_level'] ?? details['cleanliness'],
        ),
      },
      {
        'Sleep schedule':
            details['sleep_schedule']?.toString() ?? 'Not specified',
      },
      {'Social level': details['social_level']?.toString() ?? 'Not specified'},
      {
        'Noise preference':
            details['noise_preference']?.toString() ?? 'Not specified',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Roommate Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profilePhoto(roommate.imageUrl),
                const SizedBox(height: 18),
                Text(
                  '${roommate.name}${roommate.age > 0 ? ', ${roommate.age}' : ''}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registered ApnaStay user',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
                ),
                if (widget.showRequestAction) ...[
                  const SizedBox(height: 18),
                  _requestButton(),
                ],
                const SizedBox(height: 24),
                _section('Profile Details', sections),
                _section('Interests & Compatibility', [
                  {'Hobbies': _displayList(details['hobbies'])},
                  {
                    'Important factors': _displayList(
                      details['compatibility_factors'],
                    ),
                  },
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profilePhoto(String photoUrl) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: 340,
          color: AppTheme.secondaryBrandLight,
          child: photoUrl.trim().isEmpty
              ? _photoFallback()
              : CachedNetworkImage(
                  imageUrl: photoUrl.trim(),
                  width: double.infinity,
                  height: 340,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => _photoFallback(),
                ),
        ),
      ),
    ),
  );

  Widget _photoFallback() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_rounded,
          size: 64,
          color: AppTheme.secondaryBrand,
        ),
        const SizedBox(height: 6),
        Text(
          'Profile photo unavailable',
          style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
        ),
      ],
    ),
  );

  Widget _requestButton() {
    final status = _requestStatus;
    final pending = status == 'pending';
    final accepted = status == 'accepted';
    final incoming = status == 'incoming_pending';
    final declined = status == 'declined';
    final disabled =
        _checkingRequest ||
        _sendingRequest ||
        pending ||
        accepted ||
        incoming ||
        declined;
    final label = _checkingRequest
        ? 'Checking request status…'
        : _sendingRequest
        ? 'Sending request…'
        : pending
        ? 'Request sent · Awaiting response'
        : accepted
        ? 'Roommate request accepted'
        : incoming
        ? 'Respond in Roommate Requests'
        : declined
        ? 'Request was declined'
        : 'Request to be roommates';

    return FilledButton.icon(
      onPressed: disabled ? null : _sendRoommateRequest,
      icon: Icon(
        accepted ? Icons.check_circle_outline_rounded : Icons.person_add_alt_1,
      ),
      label: Text(label),
    );
  }

  String _displayList(dynamic value) {
    if (value is List) {
      final items = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return items.isEmpty ? 'Not specified' : items.join(', ');
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not specified' : text;
  }

  Widget _section(String title, List<Map<String, String>> values) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...values.map((item) {
          final entry = item.entries.first;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}
