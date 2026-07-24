import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

final _secureStorage = const FlutterSecureStorage();

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isFirstTime;
  final String? error;
  final String? token;
  final String? nis;
  final String? name;
  final String? role;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isFirstTime = false,
    this.error,
    this.token,
    this.nis,
    this.name,
    this.role,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isFirstTime,
    String? error,
    String? token,
    String? nis,
    String? name,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      error: error ?? this.error,
      token: token ?? this.token,
      nis: nis ?? this.nis,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      final savedNis = await _secureStorage.read(key: 'nis');
      final savedName = await _secureStorage.read(key: 'name');
      final savedRole = await _secureStorage.read(key: 'role');
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        nis: savedNis,
        name: savedName,
        role: savedRole,
      );
    }
  }

  Future<void> register({
    required String nis,
    required String name,
    required String birthDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isFirstTime: false);
    try {
      await _dio.post(
        ApiEndpoints.register,
        data: {'nis': nis, 'name': name, 'birthDate': birthDate},
      );
      state = state.copyWith(
        isLoading: false,
        isFirstTime: true,
        nis: nis,
        name: name,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> verifyOtp(String otp) async {
    final nis = state.nis;
    if (nis == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'nis': nis, 'otp': otp},
      );
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> setPassword(String password) async {
    final nis = state.nis;
    if (nis == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiEndpoints.setPassword,
        data: {'nis': nis, 'password': password},
      );
      final data = response.data['data'];
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      await _secureStorage.write(key: 'nis', value: nis);
      await _secureStorage.write(key: 'name', value: state.name);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: accessToken,
        isFirstTime: false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> login(String nis, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'nis': nis, 'password': password},
      );
      final data = response.data['data'];
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = data['user'];

      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      await _secureStorage.write(key: 'nis', value: nis);
      await _secureStorage.write(key: 'name', value: user['name']);
      await _secureStorage.write(key: 'role', value: user['role']);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: accessToken,
        nis: nis,
        name: user['name'],
        role: user['role'],
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {}
    await _secureStorage.deleteAll();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthNotifier(dio);
});
