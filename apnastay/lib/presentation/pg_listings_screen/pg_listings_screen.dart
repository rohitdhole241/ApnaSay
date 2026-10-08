import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_skeleton_widget.dart';
import './widgets/pg_card_widget.dart';
import './widgets/pg_filter_bar_widget.dart';
import './widgets/pg_listings_app_bar_widget.dart';
import './widgets/pg_map_placeholder_widget.dart';
import './widgets/pg_view_toggle_widget.dart';

class PgListingsScreen extends StatefulWidget {
  const PgListingsScreen({super.key});

  @override
  State<PgListingsScreen> createState() => _PgListingsScreenState();
}

enum PgViewMode { list, map }

class PgModel {
  final String id;
  final String name;
  final String locality;
  final String city;
  final String price;
  final String distance;
  final String gender;
  final String imageUrl;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String address;
  final String securityDeposit;
  final String availableBeds;
  final String availableFrom;
  final Map<String, String> rules;
  final String ownerName;
  final String ownerPhotoUrl;
  final String semanticLabel;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final String roomType;
  final bool isAvailable;
  final String postedAgo;

  const PgModel({
    required this.id,
    required this.name,
    required this.locality,
    required this.city,
    required this.price,
    required this.distance,
    required this.gender,
    required this.imageUrl,
    required this.imageUrls,
    required this.videoUrls,
    required this.address,
    required this.securityDeposit,
    required this.availableBeds,
    required this.availableFrom,
    required this.rules,
    required this.ownerName,
    required this.ownerPhotoUrl,
    required this.semanticLabel,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.roomType,
    required this.isAvailable,
    required this.postedAgo,
  });

  factory PgModel.fromApi(Map<String, dynamic> map) {
    final rawGender = map['gender']?.toString().toLowerCase();
    final gender = rawGender == 'female'
        ? 'Girls'
        : rawGender == 'male'
        ? 'Boys'
        : 'Co-ed';
    final rawImages = <String>[];
    final listedImages = map['image_urls'] as List?;
    if (listedImages != null) {
      for (final value in listedImages) {
        final url = value?.toString().trim() ?? '';
        if ((url.startsWith('https://') || url.startsWith('http://')) &&
            !rawImages.contains(url)) {
          rawImages.add(url);
        }
      }
    }
    final primaryImage = map['image_url']?.toString().trim() ?? '';
    if ((primaryImage.startsWith('https://') ||
            primaryImage.startsWith('http://')) &&
        !rawImages.contains(primaryImage)) {
      rawImages.insert(0, primaryImage);
    }
    final imageUrl = rawImages.isEmpty ? '' : rawImages.first;
    final videoUrls = <String>[];
    final listedVideos = map['video_urls'] as List?;
    if (listedVideos != null) {
      for (final value in listedVideos) {
        final url = value?.toString().trim() ?? '';
        if ((url.startsWith('https://') || url.startsWith('http://')) &&
            !videoUrls.contains(url)) {
          videoUrls.add(url);
        }
      }
    }
    final rawAmenities =
        (map['amenities'] as List?)?.whereType<String>().toList() ?? [];
    final amenities = rawAmenities
        .map((item) => item == 'Food' ? 'Meals' : item)
        .toList();
    final price = map['price'];

    return PgModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed PG',
      locality: map['locality']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      price: price is num ? price.toStringAsFixed(0) : price?.toString() ?? '-',
      distance: map['distance']?.toString() ?? 'Nearby',
      gender: gender,
      imageUrl: imageUrl,
      imageUrls: rawImages,
      videoUrls: videoUrls,
      address: map['address']?.toString() ?? '',
      securityDeposit: map['security_deposit']?.toString() ?? '-',
      availableBeds: map['available_beds']?.toString() ?? '-',
      availableFrom: map['available_from']?.toString() ?? '-',
      rules: Map<String, String>.from(
        (map['rules'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            {},
      ),
      ownerName: map['owner_name']?.toString() ?? 'PG Owner',
      ownerPhotoUrl:
          (map['owner_photo_url'] ?? map['photo_url'])?.toString().trim() ?? '',
      semanticLabel: '${map['name'] ?? 'PG'} room',
      isVerified:
          map['is_verified'] == true || map['property_verified'] == true,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      amenities: amenities,
      roomType: map['room_type']?.toString() ?? 'Room details unavailable',
      isAvailable: map['is_available'] != false,
      postedAgo: 'Recently added',
    );
  }
}

class _PgListingsScreenState extends State<PgListingsScreen> {
  PgViewMode _viewMode = PgViewMode.list;
  bool _isLoading = true;
  bool _isSearchActive = false;
  String _activeFilter = 'All';
  final ApiClient _apiClient = ApiClient();
  List<PgModel> _allPgs = [];
  List<PgModel> _filteredPgs = [];

  @override
  void initState() {
    super.initState();
    _loadPgs();
  }

  Future<void> _loadPgs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/pg/');
      final data = response.data;
      final listings = data is List
          ? data
                .map(
                  (item) =>
                      PgModel.fromApi(Map<String, dynamic>.from(item as Map)),
                )
                .toList()
          : <PgModel>[];
      if (!mounted) return;
      setState(() {
        _allPgs = listings;
        _applyFilter(_activeFilter, updateLoading: false);
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _allPgs = [];
        _filteredPgs = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load PG listings: ${error.message ?? 'Server unavailable'}',
          ),
        ),
      );
    }
  }

  void _applyFilter(String filter, {bool updateLoading = true}) {
    if (updateLoading) setState(() => _activeFilter = filter);
    _activeFilter = filter;
    final source = switch (filter) {
      'Verified' => _allPgs.where((pg) => pg.isVerified).toList(),
      'Girls' => _allPgs.where((pg) => pg.gender == 'Girls').toList(),
      'Boys' => _allPgs.where((pg) => pg.gender == 'Boys').toList(),
      'Co-ed' => _allPgs.where((pg) => pg.gender == 'Co-ed').toList(),
      'Under ₹7k' =>
        _allPgs
            .where(
              (pg) =>
                  double.tryParse(pg.price) != null &&
                  double.parse(pg.price) < 7000,
            )
            .toList(),
      'AC' => _allPgs.where((pg) => pg.amenities.contains('AC')).toList(),
      'Meals Included' =>
        _allPgs.where((pg) => pg.amenities.contains('Meals')).toList(),
      _ => List<PgModel>.from(_allPgs),
    };
    _filteredPgs = source;
  }

  Future<void> _onRefresh() => _loadPgs();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PgListingsAppBarWidget(
              isSearchActive: _isSearchActive,
              onSearchToggle: () =>
                  setState(() => _isSearchActive = !_isSearchActive),
              onBack: () => Navigator.pop(context),
            ),
            PgFilterBarWidget(
              activeFilter: _activeFilter,
              onFilterChanged: _applyFilter,
            ),
            PgViewToggleWidget(
              viewMode: _viewMode,
              onToggle: (mode) => setState(() => _viewMode = mode),
              resultCount: _filteredPgs.length,
            ),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonList()
                  : _viewMode == PgViewMode.map
                  ? const PgMapPlaceholderWidget()
                  : _buildListView(isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    itemCount: 5,
    itemBuilder: (_, __) => const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: PgCardSkeletonWidget(),
    ),
  );

  Widget _buildListView(bool isTablet) {
    if (_filteredPgs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.house_outlined,
        title: 'No PGs available yet',
        subtitle:
            'Registered PG Owners will appear here when they publish a listing.',
        ctaLabel: 'Refresh',
        onCta: _onRefresh,
        iconColor: const Color(0xFF2E6F40),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: isTablet
          ? _buildTabletGrid()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _filteredPgs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PgCardWidget(pg: _filteredPgs[index]),
              ),
            ),
    );
  }

  Widget _buildTabletGrid() => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.72,
    ),
    itemCount: _filteredPgs.length,
    itemBuilder: (context, index) => PgCardWidget(pg: _filteredPgs[index]),
  );
}
