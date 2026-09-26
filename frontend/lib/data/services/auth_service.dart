import '../../core/storage/app_storage.dart';
import '../../app/constants/app_constants.dart';
import '../models/user_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final AppStorage _storage = AppStorage();

  UserModel? get currentUser {
    final raw = _storage.read<Map<String, dynamic>>(AppConstants.userKey);
    if (raw != null) {
      return UserModel.fromJson(raw);
    }
    return DummyDataProvider.dummyUsers.first;
  }

  String? get token => _storage.read<String>(AppConstants.tokenKey);

  bool get isAuthenticated {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    UserModel? fallbackUser,
    String? impersonateToken,
  }) async {
    // If impersonateToken and fallbackUser are provided, store directly
    if (impersonateToken != null && impersonateToken.isNotEmpty && fallbackUser != null) {
      await _storage.write(AppConstants.tokenKey, impersonateToken);
      await _storage.write(AppConstants.userKey, fallbackUser.toJson());
      return {
        'success': true,
        'message': 'Login berhasil sebagai ${fallbackUser.nama}',
        'user': fallbackUser,
      };
    }

    // Attempt live API
    final res = await _api.safePost('/login', data: {
      'email': email.trim(),
      'password': password,
    });

    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final token = res.data['data']['token'];
      final userJson = res.data['data']['user'];
      final user = UserModel.fromJson(userJson);

      await _storage.write(AppConstants.tokenKey, token);
      await _storage.write(AppConstants.userKey, user.toJson());

      return {'success': true, 'message': res.data['message'], 'user': user};
    }

    // Fallback: Dummy match for prototype validation
    final cleanEmail = email.trim().toLowerCase();
    final matched = fallbackUser ??
        DummyDataProvider.dummyUsers.firstWhere(
          (u) =>
              u.email.toLowerCase() == cleanEmail ||
              (cleanEmail.startsWith('admin') && u.isAdmin) ||
              (cleanEmail.startsWith('surya') && u.id == 1) ||
              (cleanEmail.startsWith('dewi') && u.id == 2),
          orElse: () => DummyDataProvider.dummyUsers.first,
        );

    if (password.isNotEmpty || fallbackUser != null) {
      final dummyToken = impersonateToken ?? 'gurita_sanctum_token_dummy_${matched.id}';
      await _storage.write(AppConstants.tokenKey, dummyToken);
      await _storage.write(AppConstants.userKey, matched.toJson());
      return {
        'success': true,
        'message': 'Login berhasil sebagai ${matched.nama}',
        'user': matched,
      };
    }

    return {
      'success': false,
      'message': 'Email atau password tidak valid',
    };
  }

  Future<void> logout() async {
    await _api.safePost('/logout');
    await _storage.remove(AppConstants.tokenKey);
    await _storage.remove(AppConstants.userKey);
  }

  Future<UserModel?> getProfile() async {
    final res = await _api.safeGet('/profile');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final user = UserModel.fromJson(res.data['data']);
      await _storage.write(AppConstants.userKey, user.toJson());
      return user;
    }
    return currentUser;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final res = await _api.safePut('/profile', data: {
      'nama': nama,
      'email': email,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'current_password': currentPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        'new_password': newPassword,
    });

    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final updatedUser = UserModel.fromJson(res.data['data']);
      await _storage.write(AppConstants.userKey, updatedUser.toJson());
      return {'success': true, 'message': 'Profil berhasil diperbarui', 'user': updatedUser};
    }

    // Local fallback update
    final curr = currentUser!;
    final updated = curr.copyWith(nama: nama, email: email);
    await _storage.write(AppConstants.userKey, updated.toJson());
    return {'success': true, 'message': 'Profil berhasil diperbarui', 'user': updated};
  }
}
