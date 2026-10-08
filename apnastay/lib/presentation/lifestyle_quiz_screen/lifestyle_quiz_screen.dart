import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LifestyleQuizScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final bool isEditing;

  const LifestyleQuizScreen({
    super.key,
    this.initialProfile,
    this.isEditing = false,
  });

  @override
  State<LifestyleQuizScreen> createState() => _LifestyleQuizScreenState();
}

class _LifestyleQuizScreenState extends State<LifestyleQuizScreen> {
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _localitiesController = TextEditingController();
  final _budgetController = TextEditingController();
  final _moveInDateController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  String _roomType = 'Any room';
  String _pgType = 'Any PG';
  String _gender = 'Prefer not to say';
  String _distance = 'Up to 5 km';
  String _foodPreference = 'No preference';
  String _foodHabit = 'No preference';
  String _cleanliness = 'Balanced';
  String _cleaningFrequency = 'Weekly';
  String _sleepSchedule = 'Flexible';
  String _wakeUpTime = '7-9 AM';
  String _noisePreference = 'Moderate';
  String _socialLevel = 'Balanced';
  String _weekendLifestyle = 'Mix of both';
  String _occupation = 'Student';
  String _studyEnvironment = 'Quiet';
  String _personality = 'Easy-going';
  final Set<String> _hobbies = {};
  final Set<String> _compatibilityFactors = {};
  final AuthService _authService = AuthService();
  XFile? _profilePhoto;
  bool _isSaving = false;

  Map<String, dynamic> get _profile => widget.initialProfile ?? const {};

  @override
  void dispose() {
    for (final controller in [
      _ageController,
      _bioController,
      _cityController,
      _localitiesController,
      _budgetController,
      _moveInDateController,
      _collegeController,
      _courseController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialProfile();
  }

  void _loadInitialProfile() {
    final profile = _profile;
    _ageController.text = profile['age']?.toString() ?? '';
    _bioController.text = profile['bio']?.toString() ?? '';
    _cityController.text = profile['city']?.toString() ?? '';
    _localitiesController.text = profile['localities']?.toString() ?? '';
    _budgetController.text = profile['budget']?.toString() ?? '';
    _moveInDateController.text = profile['move_in_date']?.toString() ?? '';
    _collegeController.text = profile['college_company']?.toString() ?? '';
    _courseController.text = profile['course_job']?.toString() ?? '';
    _roomType = _optionOrDefault(profile['room_type'], _roomType, [
      'Any room',
      'Single',
      'Double sharing',
      'Triple sharing',
    ]);
    _gender = _optionOrDefault(profile['gender'], _gender, [
      'Female',
      'Male',
      'Non-binary',
      'Prefer not to say',
    ]);
    _pgType = _optionOrDefault(profile['pg_type'], _pgType, [
      'Any PG',
      'Boys PG',
      'Girls PG',
      'Co-living',
    ]);
    _distance = _optionOrDefault(profile['distance'], _distance, [
      'Up to 2 km',
      'Up to 5 km',
      'Up to 10 km',
    ]);
    _foodPreference = _optionOrDefault(
      profile['food_preference'],
      _foodPreference,
      ['No preference', 'Vegetarian', 'Non-vegetarian', 'Eggetarian'],
    );
    _foodHabit = _optionOrDefault(profile['food_habit'], _foodHabit, [
      'No preference',
      'Home-cooked',
      'Dabbas',
      'I cook',
    ]);
    _cleanliness = _optionOrDefault(
      profile['cleanliness_level'],
      _cleanliness,
      ['Relaxed', 'Balanced', 'Very particular'],
    );
    _cleaningFrequency = _optionOrDefault(
      profile['cleaning_frequency'],
      _cleaningFrequency,
      ['Daily', 'Weekly', 'When needed'],
    );
    _sleepSchedule = _optionOrDefault(
      profile['sleep_schedule'],
      _sleepSchedule,
      ['Early sleeper', 'Flexible', 'Night owl'],
    );
    _wakeUpTime = _optionOrDefault(profile['wake_up_time'], _wakeUpTime, [
      'Before 7 AM',
      '7-9 AM',
      'After 9 AM',
    ]);
    _noisePreference = _optionOrDefault(
      profile['noise_preference'],
      _noisePreference,
      ['Quiet', 'Moderate', 'Lively'],
    );
    _socialLevel = _optionOrDefault(profile['social_level'], _socialLevel, [
      'Introvert',
      'Balanced',
      'Very social',
    ]);
    _weekendLifestyle = _optionOrDefault(
      profile['weekend_lifestyle'],
      _weekendLifestyle,
      ['Mostly at home', 'Mix of both', 'Out and about'],
    );
    _occupation = _optionOrDefault(profile['occupation'], _occupation, [
      'Student',
      'Working professional',
      'Entrepreneur',
      'Other',
    ]);
    _studyEnvironment = _optionOrDefault(
      profile['study_environment'],
      _studyEnvironment,
      ['Quiet', 'Collaborative', 'Flexible'],
    );
    _personality = _optionOrDefault(
      profile['preferred_personality'],
      _personality,
      ['Easy-going', 'Organized', 'Outgoing', 'Quiet'],
    );
    _hobbies.addAll(_stringList(profile['hobbies']));
    _compatibilityFactors.addAll(_stringList(profile['compatibility_factors']));
  }

  String _optionOrDefault(
    dynamic value,
    String fallback,
    List<String> options,
  ) {
    final candidate = value?.toString();
    return candidate != null && options.contains(candidate)
        ? candidate
        : fallback;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.whereType<String>().toList();
  }

  Future<void> _completeProfile() async {
    if (_cityController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your city and budget.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? photoUrl;
      if (_profilePhoto != null) {
        photoUrl = await _authService.uploadImage(
          bytes: await _profilePhoto!.readAsBytes(),
          filename: _profilePhoto!.name,
          category: 'profile_photo',
        );
      }

      await _authService.updateProfile({
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _gender,
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'localities': _localitiesController.text.trim(),
        'budget': _budgetController.text.trim(),
        'move_in_date': _moveInDateController.text.trim(),
        'room_type': _roomType,
        'pg_type': _pgType,
        'distance': _distance,
        'food_preference': _foodPreference,
        'food_habit': _foodHabit,
        'cleanliness_level': _cleanliness,
        'cleaning_frequency': _cleaningFrequency,
        'sleep_schedule': _sleepSchedule,
        'wake_up_time': _wakeUpTime,
        'noise_preference': _noisePreference,
        'social_level': _socialLevel,
        'weekend_lifestyle': _weekendLifestyle,
        'hobbies': _hobbies.toList(),
        'occupation': _occupation,
        'college_company': _collegeController.text.trim(),
        'course_job': _courseController.text.trim(),
        'study_environment': _studyEnvironment,
        'preferred_personality': _personality,
        'compatibility_factors': _compatibilityFactors.toList(),
        if (photoUrl != null) 'photo_url': photoUrl,
      });
      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeDashboardScreen,
          (route) => false,
        );
      }
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your profile: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit your profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing
                    ? 'Edit Your Profile'
                    : 'Complete Your Profile',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Help us find a PG and roommate that fit your lifestyle.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 24),
              _section('Basic Information', Icons.person_outline, [
                _field(
                  'Age (optional)',
                  _ageController,
                  keyboardType: TextInputType.number,
                ),
                _dropdown(
                  'Gender',
                  _gender,
                  ['Female', 'Male', 'Non-binary', 'Prefer not to say'],
                  (value) => setState(() => _gender = value!),
                ),
                _field('Bio', _bioController, maxLines: 3),
                _photoPicker(),
              ]),
              _section('PG Preferences', Icons.location_on_outlined, [
                _field('City', _cityController),
                _field('Preferred localities', _localitiesController),
                _field(
                  'Monthly budget',
                  _budgetController,
                  keyboardType: TextInputType.number,
                ),
                _dateField('Move-in date', _moveInDateController),
                _dropdown(
                  'Room type',
                  _roomType,
                  ['Any room', 'Single', 'Double sharing', 'Triple sharing'],
                  (value) => setState(() => _roomType = value!),
                ),
                _dropdown('PG type', _pgType, [
                  'Any PG',
                  'Boys PG',
                  'Girls PG',
                  'Co-living',
                ], (value) => setState(() => _pgType = value!)),
                _dropdown(
                  'Distance from preferred area',
                  _distance,
                  ['Up to 2 km', 'Up to 5 km', 'Up to 10 km'],
                  (value) => setState(() => _distance = value!),
                ),
              ]),
              _section('Food', Icons.restaurant_outlined, [
                _dropdown(
                  'Food preference',
                  _foodPreference,
                  [
                    'No preference',
                    'Vegetarian',
                    'Non-vegetarian',
                    'Eggetarian',
                  ],
                  (value) => setState(() => _foodPreference = value!),
                ),
                _dropdown(
                  'Food habit',
                  _foodHabit,
                  ['No preference', 'Home-cooked', 'Dabbas', 'I cook'],
                  (value) => setState(() => _foodHabit = value!),
                ),
              ]),
              _section('Cleanliness', Icons.cleaning_services_outlined, [
                _dropdown(
                  'Cleanliness level',
                  _cleanliness,
                  ['Relaxed', 'Balanced', 'Very particular'],
                  (value) => setState(() => _cleanliness = value!),
                ),
                _dropdown(
                  'Cleaning frequency',
                  _cleaningFrequency,
                  ['Daily', 'Weekly', 'When needed'],
                  (value) => setState(() => _cleaningFrequency = value!),
                ),
              ]),
              _section('Sleep & Routine', Icons.nightlight_outlined, [
                _dropdown(
                  'Sleep schedule',
                  _sleepSchedule,
                  ['Early sleeper', 'Flexible', 'Night owl'],
                  (value) => setState(() => _sleepSchedule = value!),
                ),
                _dropdown(
                  'Wake-up time',
                  _wakeUpTime,
                  ['Before 7 AM', '7-9 AM', 'After 9 AM'],
                  (value) => setState(() => _wakeUpTime = value!),
                ),
                _dropdown(
                  'Noise preference',
                  _noisePreference,
                  ['Quiet', 'Moderate', 'Lively'],
                  (value) => setState(() => _noisePreference = value!),
                ),
              ]),
              _section('Social Vibe', Icons.groups_outlined, [
                _dropdown(
                  'Social level',
                  _socialLevel,
                  ['Introvert', 'Balanced', 'Very social'],
                  (value) => setState(() => _socialLevel = value!),
                ),
                _dropdown(
                  'Weekend lifestyle',
                  _weekendLifestyle,
                  ['Mostly at home', 'Mix of both', 'Out and about'],
                  (value) => setState(() => _weekendLifestyle = value!),
                ),
              ]),
              _section('Interests', Icons.interests_outlined, [
                _chips([
                  'Music',
                  'Sports',
                  'Gaming',
                  'Reading',
                  'Travel',
                  'Cooking',
                ], _hobbies),
              ]),
              _section('Study / Work', Icons.school_outlined, [
                _dropdown(
                  'Occupation',
                  _occupation,
                  ['Student', 'Working professional', 'Entrepreneur', 'Other'],
                  (value) => setState(() => _occupation = value!),
                ),
                _field('College / company', _collegeController),
                _field('Course / job', _courseController),
                _dropdown(
                  'Study environment',
                  _studyEnvironment,
                  ['Quiet', 'Collaborative', 'Flexible'],
                  (value) => setState(() => _studyEnvironment = value!),
                ),
              ]),
              _section('Roommate Preferences', Icons.handshake_outlined, [
                _dropdown(
                  'Preferred personality',
                  _personality,
                  ['Easy-going', 'Organized', 'Outgoing', 'Quiet'],
                  (value) => setState(() => _personality = value!),
                ),
                _chips([
                  'Cleanliness',
                  'Budget',
                  'Sleep schedule',
                  'Food',
                  'Privacy',
                  'Location',
                ], _compatibilityFactors),
              ]),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _completeProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save & Continue',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
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
                Icon(icon, color: AppTheme.primaryBrand),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
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
    TextEditingController controller, {
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
          decoration: _fieldDecoration(),
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
          onTap: () => _selectMoveInDate(controller),
          decoration: _fieldDecoration(
            suffixIcon: const Icon(Icons.calendar_month_outlined),
          ),
        ),
      ],
    ),
  );

  Future<void> _selectMoveInDate(TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selectedDate == null || !mounted) return;
    controller.text = MaterialLocalizations.of(
      context,
    ).formatMediumDate(selectedDate);
  }

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
          decoration: _fieldDecoration(),
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

  Widget _inputLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.onSurfaceMuted,
    ),
  );

  InputDecoration _fieldDecoration({Widget? suffixIcon}) => InputDecoration(
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppTheme.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  Widget _chips(List<String> labels, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: labels
        .map(
          (label) => FilterChip(
            label: Text(label),
            selected: selected.contains(label),
            onSelected: (isSelected) => setState(
              () => isSelected ? selected.add(label) : selected.remove(label),
            ),
          ),
        )
        .toList(),
  );

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null && mounted) {
      setState(() => _profilePhoto = photo);
    }
  }

  Widget _photoPicker() => OutlinedButton.icon(
    onPressed: _pickPhoto,
    icon: const Icon(Icons.add_a_photo_outlined),
    label: Text(_profilePhoto == null ? 'Add photo' : 'Photo selected'),
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  );
}
