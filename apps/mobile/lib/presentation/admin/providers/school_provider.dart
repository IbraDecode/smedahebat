import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class SchoolState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> academicYears;
  final bool isUpdating;
  final bool isCreatingYear;
  final bool isDeletingYear;
  final bool isSettingActive;

  const SchoolState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.academicYears = const [],
    this.isUpdating = false,
    this.isCreatingYear = false,
    this.isDeletingYear = false,
    this.isSettingActive = false,
  });

  SchoolState copyWith({
    bool? isLoading,
    bool clearError = false,
    String? error,
    Map<String, dynamic>? profile,
    List<Map<String, dynamic>>? academicYears,
    bool? isUpdating,
    bool? isCreatingYear,
    bool? isDeletingYear,
    bool? isSettingActive,
  }) {
    return SchoolState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
      academicYears: academicYears ?? this.academicYears,
      isUpdating: isUpdating ?? this.isUpdating,
      isCreatingYear: isCreatingYear ?? this.isCreatingYear,
      isDeletingYear: isDeletingYear ?? this.isDeletingYear,
      isSettingActive: isSettingActive ?? this.isSettingActive,
    );
  }
}

class SchoolNotifier extends StateNotifier<SchoolState> {
  final Dio _dio;

  SchoolNotifier(this._dio) : super(const SchoolState());

  Future<void> fetchSchoolProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.schoolProfile);
      final data = response.data is Map
          ? response.data['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(isLoading: false, profile: data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> updateSchoolProfile(Map<String, dynamic> dto) async {
    state = state.copyWith(isUpdating: true, clearError: true);
    try {
      final response = await _dio.patch(ApiEndpoints.schoolProfile, data: dto);
      final data = response.data is Map
          ? response.data['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(isUpdating: false, profile: data);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isUpdating: false, error: msg);
      return msg;
    }
  }

  Future<void> fetchAcademicYears() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.academicYears);
      final List<dynamic> items = response.data['data'] is List
          ? response.data['data'] as List<dynamic>
          : [];
      state = state.copyWith(
        isLoading: false,
        academicYears: items.cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> createAcademicYear(Map<String, dynamic> dto) async {
    state = state.copyWith(isCreatingYear: true, clearError: true);
    try {
      await _dio.post(ApiEndpoints.academicYears, data: dto);
      state = state.copyWith(isCreatingYear: false);
      await fetchAcademicYears();
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isCreatingYear: false, error: msg);
      return msg;
    }
  }

  Future<String?> setActiveYear(String id) async {
    state = state.copyWith(isSettingActive: true, clearError: true);
    try {
      await _dio.patch('${ApiEndpoints.academicYears}/$id/activate');
      state = state.copyWith(isSettingActive: false);
      await fetchAcademicYears();
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isSettingActive: false, error: msg);
      return msg;
    }
  }

  Future<String?> deleteAcademicYear(String id) async {
    state = state.copyWith(isDeletingYear: true, clearError: true);
    try {
      await _dio.delete('${ApiEndpoints.academicYears}/$id');
      state = state.copyWith(isDeletingYear: false);
      await fetchAcademicYears();
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isDeletingYear: false, error: msg);
      return msg;
    }
  }
}

final schoolProvider =
    StateNotifierProvider<SchoolNotifier, SchoolState>((ref) {
  final dio = ref.watch(dioProvider);
  return SchoolNotifier(dio);
});
