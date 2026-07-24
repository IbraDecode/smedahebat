import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class GradeComponent {
  final String id;
  final String name;
  final String type;
  final double weight;
  final int maxScore;
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const GradeComponent({
    required this.id,
    this.name = '',
    this.type = 'Tugas',
    this.weight = 0,
    this.maxScore = 100,
    this.subjectId = '',
    this.subjectName = '',
    this.classId = '',
    this.className = '',
  });

  factory GradeComponent.fromJson(Map<String, dynamic> json) {
    return GradeComponent(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Tugas',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      maxScore: json['maxScore'] as int? ?? 100,
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className'] as String? ?? '',
    );
  }
}

class ScoreItem {
  final String id;
  final String studentId;
  final String studentName;
  final String studentNis;
  final int? score;
  final int maxScore;
  final String componentName;

  const ScoreItem({
    required this.id,
    this.studentId = '',
    this.studentName = '',
    this.studentNis = '',
    this.score,
    this.maxScore = 100,
    this.componentName = '',
  });

  factory ScoreItem.fromJson(Map<String, dynamic> json) {
    return ScoreItem(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentNis: json['studentNis'] as String? ?? '',
      score: json['score'] as int?,
      maxScore: json['maxScore'] as int? ?? 100,
      componentName: json['componentName'] as String? ?? '',
    );
  }
}

class StudentScores {
  final double average;
  final int total;
  final Map<String, List<ScoreItem>> subjects;

  const StudentScores({
    this.average = 0,
    this.total = 0,
    this.subjects = const {},
  });

  factory StudentScores.fromJson(Map<String, dynamic> json) {
    final subjectsRaw = json['subjects'] as Map<String, dynamic>? ?? {};
    final subjects = subjectsRaw.map((key, value) {
      final list = (value as List<dynamic>?)
              ?.map((e) => ScoreItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return MapEntry(key, list);
    });
    return StudentScores(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      total: json['total'] as int? ?? 0,
      subjects: subjects,
    );
  }
}

class SubjectGrade {
  final String subjectName;
  final double score;
  final String grade;
  final String description;

  const SubjectGrade({
    this.subjectName = '',
    this.score = 0,
    this.grade = '',
    this.description = '',
  });

  factory SubjectGrade.fromJson(Map<String, dynamic> json) {
    return SubjectGrade(
      subjectName: json['subjectName'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class ReportCard {
  final String id;
  final String studentId;
  final String studentName;
  final String studentNis;
  final String className;
  final String academicYear;
  final String semester;
  final String status;
  final double totalScore;
  final double average;
  final int rank;
  final String? notes;
  final String? publishedAt;
  final String schoolName;
  final List<SubjectGrade> subjects;

  const ReportCard({
    required this.id,
    this.studentId = '',
    this.studentName = '',
    this.studentNis = '',
    this.className = '',
    this.academicYear = '',
    this.semester = '',
    this.status = 'draft',
    this.totalScore = 0,
    this.average = 0,
    this.rank = 0,
    this.notes,
    this.publishedAt,
    this.schoolName = '',
    this.subjects = const [],
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentNis: json['studentNis'] as String? ?? '',
      className: json['className'] as String? ?? '',
      academicYear: json['academicYear'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] as int? ?? 0,
      notes: json['notes'] as String?,
      publishedAt: json['publishedAt'] as String?,
      schoolName: json['schoolName'] as String? ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => SubjectGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GradeState {
  final bool isLoading;
  final String? error;
  final List<GradeComponent> components;
  final List<ScoreItem> scores;
  final StudentScores? myScores;
  final ReportCard? myRapor;
  final List<ReportCard> classRapors;

  const GradeState({
    this.isLoading = false,
    this.error,
    this.components = const [],
    this.scores = const [],
    this.myScores,
    this.myRapor,
    this.classRapors = const [],
  });

  GradeState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<GradeComponent>? components,
    List<ScoreItem>? scores,
    StudentScores? myScores,
    bool clearMyScores = false,
    ReportCard? myRapor,
    bool clearMyRapor = false,
    List<ReportCard>? classRapors,
  }) {
    return GradeState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      components: components ?? this.components,
      scores: scores ?? this.scores,
      myScores: clearMyScores ? null : (myScores ?? this.myScores),
      myRapor: clearMyRapor ? null : (myRapor ?? this.myRapor),
      classRapors: classRapors ?? this.classRapors,
    );
  }
}

class GradeNotifier extends StateNotifier<GradeState> {
  final Dio _dio;

  GradeNotifier(this._dio) : super(const GradeState());

  Future<void> fetchComponents({String? subjectId, String? classId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (subjectId != null) params['subjectId'] = subjectId;
      if (classId != null) params['classId'] = classId;
      final response = await _dio.get(
        ApiEndpoints.gradeComponents,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        components: items
            .map((e) => GradeComponent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> createComponent(Map<String, dynamic> dto) async {
    try {
      await _dio.post(ApiEndpoints.gradeComponents, data: dto);
      await fetchComponents(
        subjectId: dto['subjectId'] as String?,
        classId: dto['classId'] as String?,
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> updateComponent(String id, Map<String, dynamic> dto) async {
    try {
      await _dio.patch('${ApiEndpoints.gradeComponents}/$id', data: dto);
      await fetchComponents(
        subjectId: dto['subjectId'] as String?,
        classId: dto['classId'] as String?,
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> deleteComponent(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.gradeComponents}/$id');
      state = state.copyWith(
        components: state.components.where((c) => c.id != id).toList(),
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<void> fetchScoresByComponent(String componentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        ApiEndpoints.gradeScores,
        queryParameters: {'componentId': componentId},
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        scores: items
            .map((e) => ScoreItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> inputScore({
    required String componentId,
    required String studentId,
    required int score,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.gradeScores,
        data: {'componentId': componentId, 'studentId': studentId, 'score': score},
      );
      await fetchScoresByComponent(componentId);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> inputBulkScores({
    required String componentId,
    required List<Map<String, dynamic>> scores,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.gradeScoresBulk,
        data: {'componentId': componentId, 'scores': scores},
      );
      await fetchScoresByComponent(componentId);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<void> fetchMyScores() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.gradeScoresMy);
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(
        isLoading: false,
        myScores: data != null ? StudentScores.fromJson(data) : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchMyRapor() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.gradeRaporMy);
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(
        isLoading: false,
        myRapor: data != null ? ReportCard.fromJson(data) : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> generateRapor({
    required String classId,
    required String academicYearId,
    required String semester,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post(
        ApiEndpoints.gradeRaporGenerate,
        data: {
          'classId': classId,
          'academicYearId': academicYearId,
          'semester': semester,
        },
      );
      state = state.copyWith(isLoading: false);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> fetchClassRapors(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.gradeRapor}/class/$classId',
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        classRapors: items
            .map((e) => ReportCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> publishRapor(String id) async {
    try {
      await _dio.patch('${ApiEndpoints.gradeRapor}/$id/publish');
      state = state.copyWith(
        classRapors: state.classRapors.map((r) {
          if (r.id == id) {
            return ReportCard(
              id: r.id,
              studentId: r.studentId,
              studentName: r.studentName,
              studentNis: r.studentNis,
              className: r.className,
              academicYear: r.academicYear,
              semester: r.semester,
              status: 'published',
              totalScore: r.totalScore,
              average: r.average,
              rank: r.rank,
              notes: r.notes,
              publishedAt: DateTime.now().toIso8601String(),
              schoolName: r.schoolName,
              subjects: r.subjects,
            );
          }
          return r;
        }).toList(),
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  void clearError() {
    state = state.copyWith(error: null, clearError: true);
  }
}

final gradeProvider = StateNotifierProvider<GradeNotifier, GradeState>((ref) {
  final dio = ref.watch(dioProvider);
  return GradeNotifier(dio);
});
