import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_client.dart';

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phoneRegex = RegExp(r'^\d{10}$');
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  );

  final FirebaseAuth _firebaseAuth;
  final ApiClient _apiClient;

  AuthService({FirebaseAuth? firebaseAuth, ApiClient? apiClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _apiClient = apiClient ?? ApiClient();

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address with @.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'Phone number is required.';
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Phone number must be exactly 10 digits.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!_passwordRegex.hasMatch(password)) {
      return 'Password must include upper, lower, number and special character.';
    }
    return null;
  }

  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? pgName,
    String? kitchenName,
    int? age,
    String? gender,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPhone = phone.trim();

    if (trimmedName.isEmpty) {
      throw const AuthServiceException(
        'Enter your full name to create an account.',
      );
    }

    final emailError = _validateEmail(trimmedEmail);
    if (emailError != null) throw AuthServiceException(emailError);

    final phoneError = _validatePhone(trimmedPhone);
    if (phoneError != null) throw AuthServiceException(phoneError);

    final passwordError = _validatePassword(password);
    if (passwordError != null) throw AuthServiceException(passwordError);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Firebase account creation failed.');
      }

      await user.updateDisplayName(trimmedName);

      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }

      final body = <String, dynamic>{
        'name': trimmedName,
        'email': trimmedEmail,
        'phone': trimmedPhone,
        'password': password,
        'role': role,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (pgName != null && pgName.trim().isNotEmpty)
          'pg_name': pgName.trim(),
        if (kitchenName != null && kitchenName.trim().isNotEmpty)
          'kitchen_name': kitchenName.trim(),
      };

      final response = await _apiClient.post(
        '/users/',
        body: body,
        idToken: idToken,
      );
      final data = response.data;
      if (data is! Map) {
        throw const AuthServiceException(
          'The backend returned an unexpected response.',
        );
      }

      return Map<String, dynamic>.from(data);
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-email':
          throw const AuthServiceException('The email address is invalid.');
        case 'email-already-in-use':
          throw const AuthServiceException('This email is already registered.');
        case 'weak-password':
          throw const AuthServiceException(
            'Password is too weak. Use a stronger password.',
          );
        case 'network-request-failed':
          throw const AuthServiceException(
            'Network error while creating the account.',
          );
        default:
          throw AuthServiceException(
            'Firebase account creation failed: ${error.message ?? error.code}',
          );
      }
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Backend account creation failed: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final emailError = _validateEmail(email);
    if (emailError != null) throw AuthServiceException(emailError);

    if (password.trim().isEmpty) {
      throw const AuthServiceException('Password is required.');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Firebase sign-in failed.');
      }

      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }

      final response = await _apiClient.get('/users/me', idToken: idToken);
      final data = response.data;
      if (data is! Map) {
        throw const AuthServiceException(
          'The backend returned an unexpected response.',
        );
      }

      return Map<String, dynamic>.from(data);
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-email':
          throw const AuthServiceException('The email is invalid.');
        case 'user-not-found':
          throw const AuthServiceException(
            'No account found with this email. Create an account first.',
          );
        case 'wrong-password':
          throw const AuthServiceException(
            'Incorrect password. Please try again.',
          );
        case 'user-disabled':
          throw const AuthServiceException('This account has been disabled.');
        default:
          throw AuthServiceException(
            'Firebase sign-in failed: ${error.message ?? error.code}',
          );
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        throw const AuthServiceException(
          'No user profile was found for this account.',
        );
      }
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Backend sign-in failed: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in before completing your profile.',
      );
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }

    try {
      await _apiClient.put('/users/me', body: profile, idToken: idToken);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not save your profile: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
    required String category,
    String? pgId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in before uploading images.',
      );
    }
    if (bytes.isEmpty) {
      throw const AuthServiceException('The selected image is empty.');
    }

    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }
      final response = await _apiClient.uploadImage(
        '/media/upload',
        bytes: bytes,
        filename: filename,
        category: category,
        pgId: pgId,
        idToken: idToken,
      );
      final data = response.data;
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        throw const AuthServiceException(
          'The backend did not return an image URL.',
        );
      }
      return url;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not upload the image: ${error.message ?? 'Unknown error'}',
      );
    } on ArgumentError catch (error) {
      throw AuthServiceException(
        error.message?.toString() ?? 'Unsupported image type.',
      );
    }
  }

  Future<String> uploadVideo({
    required List<int> bytes,
    required String filename,
    String category = 'pg_video',
    String? pgId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in before uploading a video.',
      );
    }
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }
      final response = await _apiClient.uploadVideo(
        '/media/upload-video',
        bytes: bytes,
        filename: filename,
        category: category,
        pgId: pgId,
        idToken: idToken,
      );
      final data = response.data;
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        throw const AuthServiceException(
          'The backend did not return a video URL.',
        );
      }
      return url;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not upload the video: ${error.message ?? 'Unknown error'}',
      );
    } on ArgumentError catch (error) {
      throw AuthServiceException(
        error.message?.toString() ?? 'Unsupported video type.',
      );
    }
  }

  Future<Map<String, dynamic>> getCurrentProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in to view your profile.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }

    try {
      final response = await _apiClient.get('/users/me', idToken: idToken);
      final data = response.data;
      if (data is! Map) {
        throw const AuthServiceException(
          'The backend returned an unexpected profile response.',
        );
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load your profile: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> createPg(Map<String, dynamic> listing) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in as a PG owner first.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }

    try {
      await _apiClient.post('/pg/', body: listing, idToken: idToken);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not create the PG listing: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyPgs() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in as a PG owner first.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get('/pg/mine', idToken: idToken);
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on DioException catch (error) {
      throw AuthServiceException(
        'Could not load your PG listings: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> updatePg(String id, Map<String, dynamic> listing) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in as a PG owner first.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.put('/pg/$id', body: listing, idToken: idToken);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not update your PG listing: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> createBooking({
    required String pgId,
    required double amount,
    required String duration,
    String? moveInDate,
    String? roomType,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to request a PG booking.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.post(
        '/bookings/',
        body: {
          'pg_id': pgId,
          'amount': amount,
          'duration': duration,
          if (moveInDate != null && moveInDate.isNotEmpty)
            'move_in_date': moveInDate,
          if (roomType != null && roomType.isNotEmpty) 'room_type': roomType,
        },
        idToken: idToken,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw AuthServiceException(
        'Could not send the booking request: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to view your booking updates.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get('/bookings/my', idToken: idToken);
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid booking list.',
        );
      }
      return data
          .whereType<Map>()
          .map((booking) => Map<String, dynamic>.from(booking))
          .toList();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load your booking updates: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getOwnerBookings() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to view booking requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/bookings/owner',
        idToken: idToken,
      );
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid booking list.',
        );
      }
      return data
          .whereType<Map>()
          .map((booking) => Map<String, dynamic>.from(booking))
          .toList();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load booking requests: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> respondToBooking({
    required String bookingId,
    required String status,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to respond to requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.patch(
        '/bookings/${Uri.encodeComponent(bookingId)}',
        body: {'status': status},
        idToken: idToken,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw AuthServiceException(
        'Could not update the booking request: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> createMealBooking({
    required String providerUid,
    required String servicePlan,
    required double amount,
    required String deliveryAddress,
    String? notes,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to book a meal service.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.post(
        '/meal-bookings/',
        idToken: idToken,
        body: {
          'provider_uid': providerUid,
          'service_plan': servicePlan,
          'amount': amount,
          'delivery_address': deliveryAddress,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw const AuthServiceException(
        'Could not send the meal service request.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyMealBookings() async {
    return _getMealBookings('/meal-bookings/my');
  }

  Future<List<Map<String, dynamic>>> getProviderMealBookings() async {
    return _getMealBookings('/meal-bookings/provider', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> _getMealBookings(
    String path, {
    bool authenticated = true,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (authenticated && user == null) {
      throw const AuthServiceException('Please sign in to view meal requests.');
    }
    final idToken = authenticated ? await user!.getIdToken() : null;
    if (authenticated && (idToken == null || idToken.isEmpty)) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(path, idToken: idToken);
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid meal request list.',
        );
      }
      return data
          .whereType<Map>()
          .map((booking) => Map<String, dynamic>.from(booking))
          .toList();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw const AuthServiceException('Could not load meal service requests.');
    }
  }

  Future<void> respondToMealBooking({
    required String bookingId,
    required String status,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to respond to requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.patch(
        '/meal-bookings/${Uri.encodeComponent(bookingId)}',
        idToken: idToken,
        body: {'status': status},
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        throw AuthServiceException(data['detail'].toString());
      }
      throw const AuthServiceException(
        'Could not update the meal service request.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMealProviders() async {
    try {
      final response = await _apiClient.get('/meal-providers/');
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid meal provider list.',
        );
      }

      return data
          .whereType<Map>()
          .map((provider) => Map<String, dynamic>.from(provider))
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load meal providers: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRoommates() async {
    return getRoommateRecommendations();
  }

  Future<List<Map<String, dynamic>>> getRoommateRecommendations({
    int topK = 20,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in to find roommates.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/roommates/recommendations',
        queryParameters: {'top_k': topK},
        idToken: idToken,
      );
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid roommate recommendation list.',
        );
      }

      final roommates = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is! Map) {
          throw const AuthServiceException(
            'The server returned an invalid recommended roommate profile.',
          );
        }
        roommates.add(Map<String, dynamic>.from(item));
      }
      return roommates;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load roommate recommendations: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> saveRoommateDecision({
    required String targetUid,
    required bool liked,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to save roommate decisions.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.post(
        '/roommates/decision',
        body: {'target_uid': targetUid, 'decision': liked ? 'like' : 'pass'},
        idToken: idToken,
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not save this roommate decision: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRoommateDecisions() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to load roommate decisions.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/roommates/decisions',
        idToken: idToken,
      );
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid roommate decision list.',
        );
      }
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load roommate decisions: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<String?> getRoommateRequestStatus({required String targetUid}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to check roommate requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/roommates/requests/status/${Uri.encodeComponent(targetUid)}',
        idToken: idToken,
      );
      return response.data is Map ? response.data['status']?.toString() : null;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not check the roommate request: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<Map<String, dynamic>> createRoommateRequest({
    required String targetUid,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in to request a roommate.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.post(
        '/roommates/requests',
        body: {'target_uid': targetUid},
        idToken: idToken,
      );
      if (response.data is! Map) {
        throw const AuthServiceException(
          'The server returned an invalid roommate request.',
        );
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not send the roommate request: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRoommateRequests() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to view roommate requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/roommates/requests',
        idToken: idToken,
      );
      if (response.data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid roommate request list.',
        );
      }
      return (response.data as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load roommate requests: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> respondToRoommateRequest({
    required String requestId,
    required String decision,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to respond to roommate requests.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      await _apiClient.post(
        '/roommates/requests/${Uri.encodeComponent(requestId)}/respond',
        body: {'decision': decision},
        idToken: idToken,
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not update the roommate request: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<String> createRoommatePgProposal({
    required String matchRequestId,
    required String pgId,
    required String duration,
    String? moveInDate,
    String? roomType,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in to propose a PG.');
    }
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }
      final response = await _apiClient.post(
        '/roommate-pg-proposals/',
        body: {
          'match_request_id': matchRequestId,
          'pg_id': pgId,
          'duration': duration,
          if (moveInDate != null) 'move_in_date': moveInDate,
          if (roomType != null) 'room_type': roomType,
        },
        idToken: token,
      );
      final data = response.data as Map;
      return data['id']?.toString() ?? '';
    } on DioException catch (error) {
      final detail = error.response?.data;
      throw AuthServiceException(
        detail is Map && detail['detail'] != null
            ? detail['detail'].toString()
            : 'Could not send the PG proposal: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRoommatePgProposals() async =>
      _getAuthenticatedList('/roommate-pg-proposals/my', 'PG proposals');

  Future<List<Map<String, dynamic>>> _getAuthenticatedList(
    String endpoint,
    String label,
  ) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw AuthServiceException('Please sign in to view $label.');
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }

    try {
      final response = await _apiClient.get(endpoint, idToken: idToken);

      final data = response.data;

      if (data is! List) {
        throw AuthServiceException(
          'The server returned an invalid $label list.',
        );
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }

      throw AuthServiceException(
        'Could not load $label: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<void> respondToRoommatePgProposal(
    String proposalId,
    String decision,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException('Please sign in to respond.');
    }
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw const AuthServiceException(
          'Firebase did not return an ID token.',
        );
      }
      await _apiClient.patch(
        '/roommate-pg-proposals/$proposalId',
        body: {'decision': decision},
        idToken: token,
      );
    } on DioException catch (error) {
      final detail = error.response?.data;
      throw AuthServiceException(
        detail is Map && detail['detail'] != null
            ? detail['detail'].toString()
            : 'Could not respond to this PG proposal: ${error.message ?? 'Unknown error'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLikedRoommates() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Please sign in to view liked roommates.',
      );
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException('Firebase did not return an ID token.');
    }
    try {
      final response = await _apiClient.get(
        '/roommates/likes',
        idToken: idToken,
      );
      final data = response.data;
      if (data is! List) {
        throw const AuthServiceException(
          'The server returned an invalid liked roommate list.',
        );
      }
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw AuthServiceException(responseData['detail'].toString());
      }
      throw AuthServiceException(
        'Could not load liked roommates: ${error.message ?? 'Unknown error'}',
      );
    }
  }
}
