import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

enum SubmissionStatus { pending, submitted, late, graded }

SubmissionStatus _parseSubmissionStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'submitted':
      return SubmissionStatus.submitted;
    case 'late':
      return SubmissionStatus.late;
    case 'graded':
      return SubmissionStatus.graded;
    default:
      return SubmissionStatus.pending;
  }
}

class AssignmentItem {
  final String id;
  final String title;
  final String subjectName;
  final String className;
  final String teacherName;
  final DateTime deadline;
  final int maxScore;
  final SubmissionStatus? myStatus;
  final int totalSubmissions;
  final int gradedCount;

  const AssignmentItem({
    required this.id,
    required this.title,
    this.subjectName = '',
    this.className = '',
    this.teacherName = '',
    required this.deadline,
    this.maxScore = 100,
    this.myStatus,
    this.totalSubmissions = 0,
    this.gradedCount = 0,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? json['subject']?['name'] as String? ?? '',
      className: json['className'] as String? ?? json['class']?['name'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? json['teacher']?['name'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String) ?? DateTime.now()
          : DateTime.now(),
      maxScore: json['maxScore'] as int? ?? 100,
      myStatus: json['myStatus'] != null
          ? _parseSubmissionStatus(json['myStatus'] as String?)
          : null,
      totalSubmissions: json['totalSubmissions'] as int? ?? 0,
      gradedCount: json['gradedCount'] as int? ?? 0,
    );
  }
}

class AssignmentAttachment {
  final String id;
  final String name;
  final String url;
  final int size;

  const AssignmentAttachment({
    required this.id,
    this.name = '',
    this.url = '',
    this.size = 0,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['fileName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}

class AssignmentDetail {
  final String id;
  final String title;
  final String description;
  final String subjectName;
  final String className;
  final String teacherName;
  final DateTime deadline;
  final int maxScore;
  final List<AssignmentAttachment> attachments;
  final SubmissionStatus? myStatus;
  final int totalSubmissions;
  final int gradedCount;
  final int totalStudents;

  const AssignmentDetail({
    required this.id,
    required this.title,
    this.description = '',
    this.subjectName = '',
    this.className = '',
    this.teacherName = '',
    required this.deadline,
    this.maxScore = 100,
    this.attachments = const [],
    this.myStatus,
    this.totalSubmissions = 0,
    this.gradedCount = 0,
    this.totalStudents = 0,
  });

  factory AssignmentDetail.fromJson(Map<String, dynamic> json) {
    return AssignmentDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? json['subject']?['name'] as String? ?? '',
      className: json['className'] as String? ?? json['class']?['name'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? json['teacher']?['name'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String) ?? DateTime.now()
          : DateTime.now(),
      maxScore: json['maxScore'] as int? ?? 100,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AssignmentAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      myStatus: json['myStatus'] != null
          ? _parseSubmissionStatus(json['myStatus'] as String?)
          : null,
      totalSubmissions: json['totalSubmissions'] as int? ?? 0,
      gradedCount: json['gradedCount'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
    );
  }
}

class SubmissionAttachment {
  final String id;
  final String name;
  final String url;
  final int size;

  const SubmissionAttachment({
    required this.id,
    this.name = '',
    this.url = '',
    this.size = 0,
  });

  factory SubmissionAttachment.fromJson(Map<String, dynamic> json) {
    return SubmissionAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['fileName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}

class SubmissionDetail {
  final String id;
  final String content;
  final List<SubmissionAttachment> attachments;
  final SubmissionStatus status;
  final int? score;
  final String? feedback;
  final DateTime submittedAt;
  final String? studentName;
  final String? studentNis;

  const SubmissionDetail({
    required this.id,
    this.content = '',
    this.attachments = const [],
    this.status = SubmissionStatus.pending,
    this.score,
    this.feedback,
    required this.submittedAt,
    this.studentName,
    this.studentNis,
  });

  factory SubmissionDetail.fromJson(Map<String, dynamic> json) {
    return SubmissionDetail(
      id: json['id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => SubmissionAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseSubmissionStatus(json['status'] as String?),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      studentName: json['studentName'] as String? ?? json['student']?['name'] as String?,
      studentNis: json['studentNis'] as String? ?? json['student']?['nis'] as String?,
    );
  }
}

class SubmissionItem {
  final String id;
  final String studentName;
  final String studentNis;
  final SubmissionStatus status;
  final int? score;
  final String? feedback;
  final DateTime submittedAt;

  const SubmissionItem({
    required this.id,
    this.studentName = '',
    this.studentNis = '',
    this.status = SubmissionStatus.pending,
    this.score,
    this.feedback,
    required this.submittedAt,
  });

  factory SubmissionItem.fromJson(Map<String, dynamic> json) {
    return SubmissionItem(
      id: json['id']?.toString() ?? '',
      studentName: json['studentName'] as String? ?? json['student']?['name'] as String? ?? '',
      studentNis: json['studentNis'] as String? ?? json['student']?['nis'] as String? ?? '',
      status: _parseSubmissionStatus(json['status'] as String?),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AssignmentState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<AssignmentItem> assignments;
  final AssignmentDetail? detail;
  final SubmissionDetail? mySubmission;
  final List<SubmissionItem> submissions;
  final bool hasMore;
  final int page;

  const AssignmentState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.assignments = const [],
    this.detail,
    this.mySubmission,
    this.submissions = const [],
    this.hasMore = true,
    this.page = 1,
  });

  AssignmentState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<AssignmentItem>? assignments,
    AssignmentDetail? detail,
    bool clearDetail = false,
    SubmissionDetail? mySubmission,
    bool clearMySubmission = false,
    List<SubmissionItem>? submissions,
    bool? hasMore,
    int? page,
  }) {
    return AssignmentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      assignments: assignments ?? this.assignments,
      detail: clearDetail ? null : (detail ?? this.detail),
      mySubmission: clearMySubmission ? null : (mySubmission ?? this.mySubmission),
      submissions: submissions ?? this.submissions,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class AssignmentNotifier extends StateNotifier<AssignmentState> {
  final Dio _dio;

  AssignmentNotifier(this._dio) : super(const AssignmentState());

  Future<void> fetchAssignments({String? classId, String? subjectId, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, clearError: true, page: 1, hasMore: true);
    } else if (state.page == 1) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final queryParams = <String, dynamic>{'page': state.page, 'limit': 20};
      if (classId != null) queryParams['classId'] = classId;
      if (subjectId != null) queryParams['subjectId'] = subjectId;

      final response = await _dio.get(
        ApiEndpoints.assignments,
        queryParameters: queryParams,
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      final parsed = items
          .map((e) => AssignmentItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (state.page == 1) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          assignments: parsed,
          hasMore: parsed.length >= 20,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          assignments: [...state.assignments, ...parsed],
          hasMore: parsed.length >= 20,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: msg,
      );
    }
  }

  Future<void> fetchAssignmentDetail(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('${ApiEndpoints.assignments}/$id');
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          detail: AssignmentDetail.fromJson(data),
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Data tidak ditemukan');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> createAssignment(Map<String, dynamic> dto) async {
    try {
      await _dio.post(ApiEndpoints.assignments, data: dto);
      await fetchAssignments(refresh: true);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> updateAssignment(String id, Map<String, dynamic> dto) async {
    try {
      await _dio.patch('${ApiEndpoints.assignments}/$id', data: dto);
      await fetchAssignments(refresh: true);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> deleteAssignment(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.assignments}/$id');
      state = state.copyWith(
        assignments: state.assignments.where((a) => a.id != id).toList(),
        detail: null,
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> submitAssignment(String id, {String? content, String? filePath}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final formData = FormData();
      if (content != null) formData.fields.add(MapEntry('content', content));
      if (filePath != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(filePath),
        ));
      }
      await _dio.post(
        '${ApiEndpoints.assignments}/$id/submit',
        data: formData,
      );
      state = state.copyWith(isLoading: false);
      await fetchAssignmentDetail(id);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> fetchSubmissions(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('${ApiEndpoints.assignments}/$assignmentId/submissions');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        submissions: items
            .map((e) => SubmissionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> gradeSubmission(String submissionId, int score, String feedback) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.patch(
        '${ApiEndpoints.submissions}/$submissionId/grade',
        data: {'score': score, 'feedback': feedback},
      );
      state = state.copyWith(isLoading: false);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> fetchMySubmissions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.submissionsMy);
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          mySubmission: SubmissionDetail.fromJson(data),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void clearDetail() {
    state = state.copyWith(detail: null, clearDetail: true, mySubmission: null, clearMySubmission: true);
  }

  void loadMore() {
    if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
      state = state.copyWith(page: state.page + 1);
      fetchAssignments();
    }
  }

  void clearError() {
    state = state.copyWith(error: null, clearError: true);
  }
}

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  final dio = ref.watch(dioProvider);
  return AssignmentNotifier(dio);
});
