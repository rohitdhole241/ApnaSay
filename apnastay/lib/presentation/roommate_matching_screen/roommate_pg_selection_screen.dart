import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../pg_listings_screen/pg_listings_screen.dart';

class RoommatePgSelectionScreen extends StatefulWidget {
  final String matchRequestId;
  final String roommateName;

  const RoommatePgSelectionScreen({
    super.key,
    required this.matchRequestId,
    required this.roommateName,
  });

  @override
  State<RoommatePgSelectionScreen> createState() =>
      _RoommatePgSelectionScreenState();
}

class _RoommatePgSelectionScreenState extends State<RoommatePgSelectionScreen> {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  List<PgModel> _pgs = [];
  bool _loading = true;
  String? _error;
  String? _sendingPgId;

  @override
  void initState() {
    super.initState();
    _loadPgs();
  }

  Future<void> _loadPgs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.get('/pg/');
      final data = response.data;
      final pgs = data is List
          ? data
                .whereType<Map>()
                .map((item) => PgModel.fromApi(Map<String, dynamic>.from(item)))
                .where((pg) => pg.isAvailable)
                .toList()
          : <PgModel>[];
      if (mounted) setState(() => _pgs = pgs);
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Could not load PG listings.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _propose(PgModel pg) async {
    const durations = ['1 Month', '3 Months', '6 Months', '12 Months'];
    var duration = durations.first;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose your stay length'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: durations
                .map(
                  (option) => RadioListTile<String>(
                    value: option,
                    groupValue: duration,
                    title: Text(option),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => duration = value);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, duration),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _sendingPgId = pg.id);
    try {
      await _authService.createRoommatePgProposal(
        matchRequestId: widget.matchRequestId,
        pgId: pg.id,
        duration: selected,
        roomType: pg.roomType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PG proposal sent to ${widget.roommateName}.'),
        ),
      );
      Navigator.pop(context);
    } on AuthServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sendingPgId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a PG together')),
    body: _loading
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
                  OutlinedButton(onPressed: _loadPgs, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : _pgs.isEmpty
        ? const Center(child: Text('No available PG listings right now.'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.primaryBrandLight,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pick a place and send it to your matched roommate. The booking request goes to the PG owner only after they agree.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._pgs.map(
                (pg) => Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 190,
                        child: CustomImageWidget(
                          imageUrl: pg.imageUrl,
                          semanticLabel: pg.semanticLabel,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pg.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text('${pg.locality}, ${pg.city}'),
                            const SizedBox(height: 8),
                            Text(
                              '₹${pg.price} / month · ${pg.roomType}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _sendingPgId == null
                                    ? () => _propose(pg)
                                    : null,
                                icon: _sendingPgId == pg.id
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: const Text('Propose to roommate'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}
