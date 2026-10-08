import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'widgets/dabba_card_widget.dart';

class DabbaServiceScreen extends StatefulWidget {
  const DabbaServiceScreen({super.key});

  @override
  State<DabbaServiceScreen> createState() => _DabbaServiceScreenState();
}

class _DabbaServiceScreenState extends State<DabbaServiceScreen> {
  final AuthService _authService = AuthService();
  int _navIndex = 1;
  String _activeFilter = 'All';
  bool _isLoading = true;
  String? _loadError;
  List<DabbaModel> _allProviders = [];
  List<DabbaModel> _visibleProviders = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final records = await _authService.getMealProviders();
      final providers = records
          .map(DabbaModel.fromMap)
          .where((provider) => provider.providerName.trim().isNotEmpty)
          .toList();
      if (!mounted) return;

      setState(() {
        _allProviders = providers;
        _isLoading = false;
        _applyCurrentFilter();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _applyCurrentFilter();
    });
  }

  void _applyCurrentFilter() {
    switch (_activeFilter) {
      case 'Veg':
        _visibleProviders = _allProviders.where((p) => p.isVeg).toList();
        break;
      case 'Non-veg':
        _visibleProviders = _allProviders.where((p) => p.isNonVeg).toList();
        break;
      case 'Jain':
        _visibleProviders = _allProviders.where((p) => p.isJain).toList();
        break;
      default:
        _visibleProviders = List<DabbaModel>.from(_allProviders);
    }
  }

  void _showProviderDetails(DabbaModel provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.tertiaryBrandLight,
                    child: provider.providerPhotoUrl.isEmpty
                        ? const Icon(
                            Icons.restaurant_rounded,
                            color: AppTheme.tertiaryBrand,
                          )
                        : ClipOval(
                            child: CustomImageWidget(
                              imageUrl: provider.providerPhotoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  'Meal provider ${provider.providerName}',
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.providerName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              _detailLine('Location', _location(provider)),
              _detailLine('Cuisine', provider.cuisine),
              _detailLine('Food type', provider.foodType),
              _detailLine(
                'Meals served',
                provider.mealCategories.isEmpty
                    ? 'Not specified'
                    : provider.mealCategories.join(', '),
              ),
              if (provider.pricePerMeal.isNotEmpty)
                _detailLine('Price per meal', provider.pricePerMeal),
              if (provider.weeklyPlanPrice.isNotEmpty)
                _detailLine('Weekly plan', provider.weeklyPlanPrice),
              if (provider.monthlyPlanPrice.isNotEmpty)
                _detailLine('Monthly plan', provider.monthlyPlanPrice),
              if (provider.deliveryTimings.isNotEmpty)
                _detailLine('Delivery timings', provider.deliveryTimings),
              if (provider.deliveryAreas.isNotEmpty)
                _detailLine('Delivery areas', provider.deliveryAreas),
              if (provider.deliveryCharges.isNotEmpty)
                _detailLine('Delivery charges', provider.deliveryCharges),
              if (provider.hygieneVerified)
                _detailLine('Kitchen status', 'Hygiene verified'),
              if (provider.kitchenPhotoUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                _photoGallery('Kitchen photos', provider.kitchenPhotoUrls),
              ],
              if (provider.menuPhotoUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                _photoGallery('Menu photos', provider.menuPhotoUrls),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoGallery(String title, List<String> photoUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final url = photoUrls[index];
              return GestureDetector(
                onTap: () => _showPhotoViewer(url, title),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 190,
                    height: 142,
                    color: const Color(0xFF252321),
                    alignment: Alignment.center,
                    child: CustomImageWidget(
                      imageUrl: url,
                      width: 190,
                      height: 142,
                      fit: BoxFit.contain,
                      semanticLabel: title,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPhotoViewer(String url, String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (viewerContext) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(title),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 52,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProviderPlans(DabbaModel provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          children: [
            Text(
              provider.providerName,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a plan to request this meal service.',
              style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            if (provider.pricePerMeal.isNotEmpty)
              _planOption(
                provider,
                'Per meal',
                provider.pricePerMeal,
                sheetContext,
              ),
            if (provider.weeklyPlanPrice.isNotEmpty)
              _planOption(
                provider,
                'Weekly plan',
                provider.weeklyPlanPrice,
                sheetContext,
              ),
            if (provider.monthlyPlanPrice.isNotEmpty)
              _planOption(
                provider,
                'Monthly plan',
                provider.monthlyPlanPrice,
                sheetContext,
              ),
          ],
        ),
      ),
    );
  }

  Widget _planOption(
    DabbaModel provider,
    String planName,
    String price,
    BuildContext sheetContext,
  ) {
    return Card(
      color: AppTheme.background,
      child: ListTile(
        title: Text(
          planName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(price),
        trailing: FilledButton(
          onPressed: () {
            Navigator.pop(sheetContext);
            _showMealBookingSheet(provider, planName, price);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.tertiaryBrand,
          ),
          child: const Text('Book'),
        ),
      ),
    );
  }

  void _showMealBookingSheet(
    DabbaModel provider,
    String planName,
    String price,
  ) {
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    var isSubmitting = false;
    final amount =
        double.tryParse(price.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Request meal service',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.providerName} - $planName - $price',
                    style: GoogleFonts.outfit(color: AppTheme.onSurfaceMuted),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      hintText:
                          'Enter the address where meals should be delivered',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Meal preferences or delivery instructions',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (addressController.text.trim().length < 5) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter a complete delivery address.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            try {
                              await _authService.createMealBooking(
                                providerUid: provider.id,
                                servicePlan: planName,
                                amount: amount,
                                deliveryAddress: addressController.text.trim(),
                                notes: notesController.text,
                              );
                              if (!mounted || !sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Meal service request sent to the provider.',
                                  ),
                                ),
                              );
                            } on AuthServiceException catch (error) {
                              if (!mounted) return;
                              setSheetState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              setSheetState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not send the meal request. Please try again.',
                                  ),
                                ),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.tertiaryBrand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      isSubmitting ? 'Sending request…' : 'Send request',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      addressController.dispose();
      notesController.dispose();
    });
  }

  String _location(DabbaModel provider) {
    return [
      provider.locality,
      provider.city,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dabba Service',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              'Home-cooked meals from local providers',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh providers',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.onSurface),
            onPressed: _loadProviders,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeroBanner(),
            _buildFilterRow(),
            Expanded(child: _buildProviderList()),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final count = _allProviders.length;
    final listingCount = count == 1
        ? '1 meal provider listed'
        : '$count meal providers listed';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8622A), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local meal providers',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading ? 'Loading providers...' : listingCount,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provider details and prices come from their saved profiles.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.lunch_dining_rounded,
            size: 54,
            color: Colors.white30,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const filters = ['All', 'Veg', 'Non-veg', 'Jain'];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = _activeFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: FilterChip(
              label: Text(filter),
              selected: isActive,
              onSelected: (_) => _applyFilter(filter),
              selectedColor: AppTheme.tertiaryBrandLight,
              checkmarkColor: AppTheme.tertiaryBrand,
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppTheme.tertiaryBrand
                    : AppTheme.onSurfaceMedium,
              ),
              side: BorderSide(
                color: isActive
                    ? AppTheme.tertiaryBrand.withAlpha(80)
                    : AppTheme.outline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderList() {
    if (_isLoading && _allProviders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _allProviders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load meal providers',
        subtitle: _loadError!,
        ctaLabel: 'Try again',
        onCta: _loadProviders,
        iconColor: AppTheme.tertiaryBrand,
      );
    }

    if (_allProviders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.no_meals_rounded,
        title: 'No meal providers yet',
        subtitle: 'Providers will appear here after they save their profile.',
        ctaLabel: 'Refresh',
        onCta: _loadProviders,
        iconColor: AppTheme.tertiaryBrand,
      );
    }

    if (_visibleProviders.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.no_meals_rounded,
        title: 'No providers match this filter',
        subtitle: 'Choose another food preference to see more providers.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProviders,
      color: AppTheme.tertiaryBrand,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _visibleProviders.length,
        itemBuilder: (context, index) {
          final provider = _visibleProviders[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: DabbaCardWidget(
                key: ValueKey(provider.id),
                dabba: provider,
                onViewDetails: () => _showProviderDetails(provider),
                onViewPlans: () => _showProviderPlans(provider),
              ),
            ),
          );
        },
      ),
    );
  }
}
