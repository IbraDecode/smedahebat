import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class TeacherSubjectState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> classes;

  const TeacherSubjectState({
    this.isLoading = false,
    this.error,
    this.assignments = const [],
    this.teachers = const [],
    this.subjects = const [],
    this.classes = const [],
  });

  TeacherSubjectState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? teachers,
    List<Map<String, dynamic>>? subjects,
    List<Map<String, dynamic>>? classes,
  }) {
    return TeacherSubjectState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      assignments: assignments ?? this.assignments,
      teachers: teachers ?? this.teachers,
      subjects: subjects ?? this.subjects,
      classes: classes ?? this.classes,
    );
  }
}

class TeacherSubjectNotifier extends StateNotifier<TeacherSubjectState> {
  final Dio _dio;

  TeacherSubjectNotifier(this._dio) : super(const TeacherSubjectState());

  Future<void> fetchAssignments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.teacherSubjects);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        assignments: items.cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchTeachers() async {
    try {
      final response = await _dio.get('/users', queryParameters: {'role': 'GURU'});
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(teachers: items.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> fetchSubjects() async {
    try {
      final response = await _dio.get('/academic/subjects');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(subjects: items.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> fetchClasses() async {
    try {
      final response = await _dio.get('/academic/classes');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(classes: items.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _dio.get(ApiEndpoints.teacherSubjects),
        _dio.get('/users', queryParameters: {'role': 'GURU'}),
        _dio.get('/academic/subjects'),
        _dio.get('/academic/classes'),
      ]);
      final assignmentsData = results[0].data is Map
          ? results[0].data as Map<String, dynamic>
          : <String, dynamic>{};
      final teachersData = results[1].data is Map
          ? results[1].data as Map<String, dynamic>
          : <String, dynamic>{};
      final subjectsData = results[2].data is Map
          ? results[2].data as Map<String, dynamic>
          : <String, dynamic>{};
      final classesData = results[3].data is Map
          ? results[3].data as Map<String, dynamic>
          : <String, dynamic>{};
      state = TeacherSubjectState(
        isLoading: false,
        assignments: (assignmentsData['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        teachers: (teachersData['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        subjects: (subjectsData['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        classes: (classesData['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> createAssignment(Map<String, dynamic> dto) async {
    try {
      await _dio.post(ApiEndpoints.teacherSubjects, data: dto);
      await fetchAssignments();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> updateAssignment(String id, Map<String, dynamic> dto) async {
    try {
      await _dio.patch('${ApiEndpoints.teacherSubjects}/$id', data: dto);
      await fetchAssignments();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> deleteAssignment(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.teacherSubjects}/$id');
      state = state.copyWith(
        assignments:
            state.assignments.where((a) => a['id']?.toString() != id).toList(),
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }
}

final teacherSubjectProvider =
    StateNotifierProvider<TeacherSubjectNotifier, TeacherSubjectState>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherSubjectNotifier(dio);
});
