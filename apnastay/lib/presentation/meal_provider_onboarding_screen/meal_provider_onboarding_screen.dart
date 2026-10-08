import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class MealProviderOnboardingScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialProfile;

  const MealProviderOnboardingScreen({
    super.key,
    this.isEditing = false,
    this.initialProfile,
  });

  @override
  State<MealProviderOnboardingScreen> createState() =>
      _MealProviderOnboardingScreenState();
}

class _MealProviderOnboardingScreenState
    extends State<MealProviderOnboardingScreen> {
  final _providerName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Mumbai');
  final _locality = TextEditingController();
  final _capacity = TextEditingController();
  final _perMeal = TextEditingController();
  final _weekly = TextEditingController();
  final _monthly = TextEditingController();
  final _areas = TextEditingController();
  final _timings = TextEditingController();
  final _deliveryCharges = TextEditingController();
  final _fssai = TextEditingController();
  final _authService = AuthService();
  final _picker = ImagePicker();
  final Set<String> _mealCategories = {};
  List<XFile> _kitchenPhotos = [];
  List<XFile> _menuPhotos = [];
  XFile? _providerPhoto;
  String _foodType = 'Vegetarian';
  String _cuisine = 'North Indian';
  bool _hygieneVerified = false;
  bool _saving = false;

  final _categories = const ['Breakfast', 'Lunch', 'Dinner'];
  final _cuisines = const [
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Punjabi',
    'Gujarati',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    if (!widget.isEditing) return;
    final profile = widget.initialProfile ?? const <String, dynamic>{};
    _providerName.text = profile['provider_name']?.toString() ?? '';
    _address.text = profile['kitchen_address']?.toString() ?? '';
    _city.text = profile['kitchen_city']?.toString() ?? 'Mumbai';
    _locality.text = profile['kitchen_locality']?.toString() ?? '';
    _capacity.text = profile['daily_capacity']?.toString() ?? '';
    _perMeal.text = profile['price_per_meal']?.toString() ?? '';
    _weekly.text = profile['weekly_plan_price']?.toString() ?? '';
    _monthly.text = profile['monthly_plan_price']?.toString() ?? '';
    _areas.text = profile['delivery_areas']?.toString() ?? '';
    _timings.text = profile['delivery_timings']?.toString() ?? '';
    _deliveryCharges.text = profile['delivery_charges']?.toString() ?? '';
    _fssai.text = profile['fssai_license']?.toString() ?? '';
    _foodType = _option(profile['food_type'], _foodType, [
      'Vegetarian',
      'Non-vegetarian',
      'Eggetarian',
      'Jain',
    ]);
    _cuisine = _option(profile['cuisine_type'], _cuisine, _cuisines);
    _mealCategories.addAll(
      (profile['meal_categories'] as List?)?.whereType<String>() ?? [],
    );
    _hygieneVerified = profile['hygiene_verified'] == true;
  }

  String _option(dynamic value, String fallback, List<String> options) {
    final candidate = value?.toString();
    return candidate != null && options.contains(candidate)
        ? candidate
        : fallback;
  }

  @override
  void dispose() {
    for (final controller in [
      _providerName,
      _address,
      _city,
      _locality,
      _capacity,
      _perMeal,
      _weekly,
      _monthly,
      _areas,
      _timings,
      _deliveryCharges,
      _fssai,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProviderPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null && mounted) setState(() => _providerPhoto = file);
  }

  Future<void> _pickKitchenPhotos() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty && mounted) setState(() => _kitchenPhotos = files);
  }

  Future<void> _pickMenuPhotos() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty && mounted) setState(() => _menuPhotos = files);
  }

  Future<String> _uploadImage(XFile file, String category) async {
    return _authService.uploadImage(
      bytes: await file.readAsBytes(),
      filename: file.name,
      category: category,
    );
  }

  Future<void> _save() async {
    if (_providerName.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _locality.text.trim().isEmpty ||
        _capacity.text.trim().isEmpty ||
        _perMeal.text.trim().isEmpty ||
        _areas.text.trim().isEmpty ||
        _timings.text.trim().isEmpty ||
        _mealCategories.isEmpty) {
      _message('Complete the provider, pricing, meal, and delivery details.');
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = widget.initialProfile ?? const <String, dynamic>{};
      final providerPhotoUrl = _providerPhoto == null
          ? profile['provider_photo_url']?.toString()
          : await _uploadImage(_providerPhoto!, 'provider_photo');
      final kitchenUrls = List<String>.from(
        (profile['kitchen_photo_urls'] as List?)?.whereType<String>() ?? const <String>[],
      );
      for (final photo in _kitchenPhotos) {
        kitchenUrls.add(await _uploadImage(photo, 'kitchen_photo'));
      }
      final menuUrls = List<String>.from(
        (profile['menu_photo_urls'] as List?)?.whereType<String>() ?? const <String>[],
      );
      for (final photo in _menuPhotos) {
        menuUrls.add(await _uploadImage(photo, 'menu_photo'));
      }

      await _authService.updateProfile({
        'provider_name': _providerName.text.trim(),
        'provider_photo_url': providerPhotoUrl,
        'kitchen_address': _address.text.trim(),
        'kitchen_city': _city.text.trim(),
        'kitchen_locality': _locality.text.trim(),
        'food_type': _foodType,
        'meal_categories': _mealCategories.toList(),
        'cuisine_type': _cuisine,
        'daily_capacity': int.tryParse(_capacity.text.trim()),
        'price_per_meal': _perMeal.text.trim(),
        'weekly_plan_price': _weekly.text.trim(),
        'monthly_plan_price': _monthly.text.trim(),
        'delivery_areas': _areas.text.trim(),
        'delivery_timings': _timings.text.trim(),
        'delivery_charges': _deliveryCharges.text.trim(),
        if (kitchenUrls.isNotEmpty) 'kitchen_photo_urls': kitchenUrls,
        if (menuUrls.isNotEmpty) 'menu_photo_urls': menuUrls,
        'fssai_license': _fssai.text.trim(),
        'hygiene_verified': _hygieneVerified,
      });

      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mealProviderDashboardScreen,
          (route) => false,
        );
      }
    } on AuthServiceException catch (error) {
      _stop(error.message);
    } catch (error) {
      _stop('Could not save provider details: $error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _stop(String text) {
    if (!mounted) return;
    setState(() => _saving = false);
    _message(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Meal Provider Profile'
              : 'Set Up Your Meal Service',
        ),
        backgroundColor: AppTheme.tertiaryBrand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('Provider Details', Icons.restaurant_outlined, [
              _field(
                'Kitchen or service name',
                _providerName,
                'Enter your kitchen or brand name',
              ),
              _upload(
                'Provider photo or logo',
                _providerPhoto == null
                    ? 'Add provider photo'
                    : 'Photo selected',
                _pickProviderPhoto,
                Icons.person_outline,
              ),
            ]),
            _section('Kitchen & Food Details', Icons.restaurant_menu, [
              _field(
                'Kitchen address',
                _address,
                'Enter complete kitchen address',
                maxLines: 2,
              ),
              _field('City', _city, 'Enter city'),
              _field('Locality', _locality, 'Enter locality'),
              _dropdown('Food type', _foodType, [
                'Vegetarian',
                'Non-vegetarian',
                'Eggetarian',
                'Jain',
              ], (value) => setState(() => _foodType = value!)),
              _dropdown(
                'Cuisine type',
                _cuisine,
                _cuisines,
                (value) => setState(() => _cuisine = value!),
              ),
              _inputLabel('Meal categories'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _categories
                    .map(
                      (item) => FilterChip(
                        label: Text(item),
                        selected: _mealCategories.contains(item),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _mealCategories.add(item)
                              : _mealCategories.remove(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
              _upload(
                'Kitchen photos',
                _kitchenPhotos.isEmpty
                    ? 'Add kitchen photos'
                    : '${_kitchenPhotos.length} photos selected',
                _pickKitchenPhotos,
                Icons.photo_library_outlined,
              ),
              _upload(
                'Menu photos',
                _menuPhotos.isEmpty
                    ? 'Add menu photos'
                    : '${_menuPhotos.length} photos selected',
                _pickMenuPhotos,
                Icons.menu_book_outlined,
              ),
            ]),
            _section('Pricing & Capacity', Icons.currency_rupee, [
              _field(
                'Daily meal capacity',
                _capacity,
                'Enter portions per day',
                keyboardType: TextInputType.number,
              ),
              _field(
                'Price per meal',
                _perMeal,
                'Enter price per meal',
                keyboardType: TextInputType.number,
              ),
              _field(
                'Weekly plan price',
                _weekly,
                'Enter weekly plan price',
                keyboardType: TextInputType.number,
              ),
              _field(
                'Monthly plan price',
                _monthly,
                'Enter monthly plan price',
                keyboardType: TextInputType.number,
              ),
            ]),
            _section('Delivery', Icons.delivery_dining_outlined, [
              _field('Delivery areas', _areas, 'Enter areas you deliver to'),
              _field('Delivery timings', _timings, 'Example: 11 AM - 2 PM'),
              _field(
                'Delivery charges',
                _deliveryCharges,
                'Enter delivery charges',
              ),
            ]),
            _section('Verification', Icons.verified_outlined, [
              _field('FSSAI license number', _fssai, 'Enter license number'),
              CheckboxListTile(
                value: _hygieneVerified,
                activeColor: AppTheme.tertiaryBrand,
                onChanged: (value) =>
                    setState(() => _hygieneVerified = value ?? false),
                title: const Text('Hygiene verification submitted'),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Meal Provider Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
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
            Row(
              children: [
                Icon(icon, color: AppTheme.tertiaryBrand),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _decoration(hint),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: _decoration('Select $label'),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _upload(
    String label,
    String text,
    VoidCallback onPressed,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputLabel(label),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Align(alignment: Alignment.centerLeft, child: Text(text)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.tertiaryBrand,
            side: const BorderSide(color: AppTheme.tertiaryBrand),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    ),
  );

  Widget _inputLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.onSurfaceMuted,
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppTheme.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
