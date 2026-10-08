import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class PgOwnerOnboardingScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialProfile;
  final Map<String, dynamic>? initialListing;

  const PgOwnerOnboardingScreen({
    super.key,
    this.isEditing = false,
    this.initialProfile,
    this.initialListing,
  });

  @override
  State<PgOwnerOnboardingScreen> createState() =>
      _PgOwnerOnboardingScreenState();
}

class _PgOwnerOnboardingScreenState extends State<PgOwnerOnboardingScreen> {
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _pgName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Mumbai');
  final _locality = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _beds = TextEditingController();
  final _availableFrom = TextEditingController();
  final _visitorPolicy = TextEditingController();
  final _entryTiming = TextEditingController();
  final _smokingPolicy = TextEditingController();
  final _noticePeriod = TextEditingController();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  final Set<String> _amenities = {};
  List<XFile> _photos = [];
  List<String> _existingPhotoUrls = [];
  List<String> _existingVideoUrls = [];
  XFile? _video;
  XFile? _ownerPhoto;
  String _pgType = 'Boys PG';
  String _roomType = 'Single';
  String _bathroomType = 'Attached';
  String _furnishing = 'Furnished';
  bool _identityVerified = false;
  bool _propertyVerified = false;
  bool _saving = false;

  Map<String, dynamic> get _profile => widget.initialProfile ?? const {};
  Map<String, dynamic> get _listing => widget.initialListing ?? const {};

  final _amenityOptions = const [
    'Wi-Fi',
    'Food',
    'Laundry',
    'Housekeeping',
    'Parking',
    'CCTV',
    'Power backup',
  ];

  @override
  void dispose() {
    for (final controller in [
      _ownerName,
      _phone,
      _pgName,
      _address,
      _city,
      _locality,
      _rent,
      _deposit,
      _beds,
      _availableFrom,
      _visitorPolicy,
      _entryTiming,
      _smokingPolicy,
      _noticePeriod,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (!widget.isEditing) return;
    _existingPhotoUrls =
        ((_listing['image_urls'] as List?)
            ?.whereType<String>()
            .map((url) => url.trim())
            .where(
              (url) => url.startsWith('https://') || url.startsWith('http://'),
            )
            .toList() ??
        <String>[]);
    final primaryImage = _listing['image_url']?.toString().trim() ?? '';
    if (primaryImage.startsWith('https://') ||
        primaryImage.startsWith('http://')) {
      if (!_existingPhotoUrls.contains(primaryImage)) {
        _existingPhotoUrls.insert(0, primaryImage);
      }
    }
    _existingVideoUrls =
        ((_listing['video_urls'] as List?)
            ?.whereType<String>()
            .map((url) => url.trim())
            .where(
              (url) => url.startsWith('https://') || url.startsWith('http://'),
            )
            .toList() ??
        <String>[]);
    _ownerName.text = _profile['name']?.toString() ?? '';
    _phone.text = _profile['phone']?.toString() ?? '';
    _pgName.text = _listing['name']?.toString() ?? '';
    _address.text = _listing['address']?.toString() ?? '';
    _city.text = _listing['city']?.toString() ?? 'Mumbai';
    _locality.text = _listing['locality']?.toString() ?? '';
    _rent.text = _listing['price']?.toString() ?? '';
    _deposit.text = _listing['security_deposit']?.toString() ?? '';
    _beds.text = _listing['available_beds']?.toString() ?? '';
    _availableFrom.text = _listing['available_from']?.toString() ?? '';
    _visitorPolicy.text = _rule('visitor_policy');
    _entryTiming.text = _rule('entry_exit_timing');
    _smokingPolicy.text = _rule('smoking_alcohol_policy');
    _noticePeriod.text = _rule('notice_period');
    _pgType = _option(_listing['pg_type'], _pgType, [
      'Boys PG',
      'Girls PG',
      'Co-living',
    ]);
    _roomType = _option(_listing['room_type'], _roomType, [
      'Single',
      'Double sharing',
      'Triple sharing',
    ]);
    _bathroomType = _option(_listing['bathroom_type'], _bathroomType, [
      'Attached',
      'Shared',
    ]);
    _furnishing = _option(_listing['furnishing'], _furnishing, [
      'Furnished',
      'Unfurnished',
    ]);
    _amenities.addAll(
      (_listing['amenities'] as List?)?.whereType<String>() ?? [],
    );
    _identityVerified = _listing['owner_identity_verified'] == true;
    _propertyVerified = _listing['property_verified'] == true;
  }

  String _rule(String key) =>
      (_listing['rules'] as Map?)?[key]?.toString() ?? '';

  String _option(dynamic value, String fallback, List<String> options) {
    final candidate = value?.toString();
    return candidate != null && options.contains(candidate)
        ? candidate
        : fallback;
  }

  Future<void> _pickOwnerPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null && mounted) setState(() => _ownerPhoto = photo);
  }

  Future<void> _pickPhotos() async {
    final photos = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (photos.isNotEmpty && mounted) {
      setState(() => _photos = [..._photos, ...photos]);
    }
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) setState(() => _video = video);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null && mounted) {
      _availableFrom.text = MaterialLocalizations.of(
        context,
      ).formatMediumDate(date);
    }
  }

  Future<void> _save() async {
    if ((widget.isEditing &&
            (_ownerName.text.trim().isEmpty || _phone.text.trim().isEmpty)) ||
        _pgName.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _locality.text.trim().isEmpty ||
        _rent.text.trim().isEmpty ||
        _deposit.text.trim().isEmpty ||
        _beds.text.trim().isEmpty ||
        _availableFrom.text.trim().isEmpty) {
      _message('Complete all required PG details before saving.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const AuthServiceException('Please sign in again.');
      }
      final photoUrls = List<String>.from(_existingPhotoUrls);
      for (final photo in _photos) {
        photoUrls.add(
          await _authService.uploadImage(
            bytes: await photo.readAsBytes(),
            filename: photo.name,
            category: 'pg_room',
            pgId: widget.isEditing ? _listing['id']?.toString() : null,
          ),
        );
      }
      final videoUrls = List<String>.from(_existingVideoUrls);
      if (_video != null) {
        videoUrls.add(
          await _authService.uploadVideo(
            bytes: await _video!.readAsBytes(),
            filename: _video!.name,
            pgId: widget.isEditing ? _listing['id']?.toString() : null,
          ),
        );
      }
      String? ownerPhotoUrl;
      if (_ownerPhoto != null) {
        ownerPhotoUrl = await _authService.uploadImage(
          bytes: await _ownerPhoto!.readAsBytes(),
          filename: _ownerPhoto!.name,
          category: 'owner_photo',
        );
      }

      final ownerProfileData = <String, dynamic>{
        if (widget.isEditing) 'name': _ownerName.text.trim(),
        if (widget.isEditing) 'phone': _phone.text.trim(),
        if (ownerPhotoUrl != null) 'owner_photo_url': ownerPhotoUrl,
        if (widget.isEditing) 'owner_identity_verified': _identityVerified,
      };
      if (ownerProfileData.isNotEmpty) {
        await _authService.updateProfile(ownerProfileData);
      }
      final listingData = {
        'name': _pgName.text.trim(),
        'locality': _locality.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'price': double.parse(_rent.text.trim()),
        'security_deposit': double.parse(_deposit.text.trim()),
        'available_beds': int.parse(_beds.text.trim()),
        'available_from': _availableFrom.text.trim(),
        'pg_type': _pgType,
        'gender': _pgType == 'Girls PG'
            ? 'female'
            : _pgType == 'Boys PG'
            ? 'male'
            : 'any',
        'room_type': _roomType,
        'bathroom_type': _bathroomType,
        'furnishing': _furnishing,
        'amenities': _amenities.toList(),
        'rules': {
          'visitor_policy': _visitorPolicy.text.trim(),
          'entry_exit_timing': _entryTiming.text.trim(),
          'smoking_alcohol_policy': _smokingPolicy.text.trim(),
          'notice_period': _noticePeriod.text.trim(),
        },
        'owner_identity_verified': _identityVerified,
        'property_verified': _propertyVerified,
        'image_url': photoUrls.isEmpty ? null : photoUrls.first,
        'image_urls': photoUrls,
        'video_urls': videoUrls,
        'is_available': true,
      };
      if (widget.isEditing && _listing['id'] != null) {
        await _authService.updatePg(_listing['id'].toString(), listingData);
      } else {
        await _authService.createPg(listingData);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pgOwnerDashboardScreen,
        (route) => false,
      );
    } on AuthServiceException catch (error) {
      _stopWithMessage(error.message);
    } on FormatException {
      _stopWithMessage(
        'Rent, deposit, and available beds must be valid numbers.',
      );
    } catch (error) {
      _stopWithMessage('Could not save the PG details: $error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _stopWithMessage(String text) {
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
          widget.isEditing ? 'Edit Your PG Profile' : 'Set Up Your PG',
        ),
        backgroundColor: AppTheme.secondaryBrand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isEditing)
              _section('Owner Details', Icons.person_outline, [
                _field('Owner name', _ownerName, 'Enter your full name'),
                _field(
                  'Phone number',
                  _phone,
                  'Enter your 10-digit phone number',
                  keyboardType: TextInputType.phone,
                ),
              ]),
            _section('Owner Profile Photo', Icons.person_outline, [
              _uploadButton(
                'Owner profile photo',
                _ownerPhoto != null
                    ? 'New owner photo selected'
                    : ((_profile['owner_photo_url'] ?? _profile['photo_url'])
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? 'Current photo saved · tap to replace'
                          : 'Add owner photo'),
                _pickOwnerPhoto,
                Icons.person_add_alt_1,
              ),
            ]),
            _section('PG Details', Icons.home_work_outlined, [
              _field('PG name', _pgName, 'Enter the name of your PG'),
              _field(
                'Complete address',
                _address,
                'Enter building, street, and address',
                maxLines: 2,
              ),
              _field('City', _city, 'Enter city'),
              _field('Locality', _locality, 'Enter area or locality'),
              _dropdown('PG type', _pgType, [
                'Boys PG',
                'Girls PG',
                'Co-living',
              ], (value) => setState(() => _pgType = value!)),
              _uploadButton(
                'PG photos',
                widget.isEditing
                    ? '${_existingPhotoUrls.length} uploaded · ${_photos.length} new'
                    : (_photos.isEmpty
                          ? 'Add one or more PG photos'
                          : '${_photos.length} selected · upload on save'),
                _pickPhotos,
                Icons.photo_library_outlined,
              ),
              if (_photos.isNotEmpty || _existingPhotoUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${_existingPhotoUrls.length + _photos.length} total PG photo${_existingPhotoUrls.length + _photos.length == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ),
              _uploadButton(
                'PG video',
                _video == null
                    ? (_existingVideoUrls.isEmpty
                          ? 'Add a PG video tour'
                          : '${_existingVideoUrls.length} video${_existingVideoUrls.length == 1 ? '' : 's'} uploaded · tap to replace')
                    : 'New video selected · upload on save',
                _pickVideo,
                Icons.video_library_outlined,
              ),
            ]),
            _section('Pricing & Availability', Icons.currency_rupee, [
              _field(
                'Monthly rent',
                _rent,
                'Enter monthly rent',
                keyboardType: TextInputType.number,
              ),
              _field(
                'Security deposit',
                _deposit,
                'Enter security deposit',
                keyboardType: TextInputType.number,
              ),
              _field(
                'Available beds',
                _beds,
                'Enter number of available beds',
                keyboardType: TextInputType.number,
              ),
              _dateField('Available from', _availableFrom),
            ]),
            _section('Room Details', Icons.bed_outlined, [
              _dropdown(
                'Room sharing',
                _roomType,
                ['Single', 'Double sharing', 'Triple sharing'],
                (value) => setState(() => _roomType = value!),
              ),
              _dropdown(
                'Bathroom',
                _bathroomType,
                ['Attached', 'Shared'],
                (value) => setState(() => _bathroomType = value!),
              ),
              _dropdown(
                'Furnishing',
                _furnishing,
                ['Furnished', 'Unfurnished'],
                (value) => setState(() => _furnishing = value!),
              ),
            ]),
            _section('Amenities', Icons.wifi_outlined, [_chips()]),
            _section('Rules', Icons.rule_outlined, [
              _field(
                'Visitor policy',
                _visitorPolicy,
                'Example: Visitors allowed until 9 PM',
              ),
              _field(
                'Entry and exit timing',
                _entryTiming,
                'Example: 6 AM to 11 PM',
              ),
              _field(
                'Smoking/alcohol policy',
                _smokingPolicy,
                'Describe your policy',
              ),
              _field('Notice period', _noticePeriod, 'Example: 30 days'),
            ]),
            _section('Verification', Icons.verified_user_outlined, [
              CheckboxListTile(
                value: _identityVerified,
                activeColor: AppTheme.secondaryBrand,
                onChanged: (value) =>
                    setState(() => _identityVerified = value ?? false),
                title: const Text('Owner identity verification submitted'),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _propertyVerified,
                activeColor: AppTheme.secondaryBrand,
                onChanged: (value) =>
                    setState(() => _propertyVerified = value ?? false),
                title: const Text('Property verification submitted'),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save PG Details'),
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
                Icon(icon, color: AppTheme.secondaryBrand),
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

  Widget _dateField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: _pickDate,
          decoration: _decoration(
            'Select available date',
            suffix: const Icon(Icons.calendar_month_outlined),
          ),
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

  Widget _uploadButton(
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
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.centerLeft,
            foregroundColor: AppTheme.secondaryBrand,
            side: const BorderSide(color: AppTheme.secondaryBrand),
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

  Widget _chips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _amenityOptions
        .map(
          (item) => FilterChip(
            label: Text(item),
            selected: _amenities.contains(item),
            onSelected: (selected) => setState(
              () => selected ? _amenities.add(item) : _amenities.remove(item),
            ),
          ),
        )
        .toList(),
  );

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: AppTheme.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
