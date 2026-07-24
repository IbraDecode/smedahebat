import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AttendanceRecord {
  final String id;
  final String date;
  final String subject;
  final String status;
  final String time;
  final String? className;
  final String? teacherName;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.subject,
    required this.status,
    required this.time,
    this.className,
    this.teacherName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      subject: json['subject'] as String? ?? json['subjectName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      time: json['time'] as String? ?? '',
      className: json['className'] as String? ?? json['class'] as String?,
      teacherName: json['teacherName'] as String? ?? json['teacher'] as String?,
    );
  }
}

class AttendanceRecap {
  final int total;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpa;
  final int terlambat;

  const AttendanceRecap({
    this.total = 0,
    this.hadir = 0,
    this.sakit = 0,
    this.izin = 0,
    this.alpa = 0,
    this.terlambat = 0,
  });

  factory AttendanceRecap.fromJson(Map<String, dynamic> json) {
    return AttendanceRecap(
      total: json['total'] as int? ?? 0,
      hadir: json['hadir'] as int? ?? 0,
      sakit: json['sakit'] as int? ?? 0,
      izin: json['izin'] as int? ?? 0,
      alpa: json['alpa'] as int? ?? 0,
      terlambat: json['terlambat'] as int? ?? 0,
    );
  }

  double get hadirPercent => total > 0 ? hadir / total : 0;
  double get sakitPercent => total > 0 ? sakit / total : 0;
  double get izinPercent => total > 0 ? izin / total : 0;
  double get alpaPercent => total > 0 ? alpa / total : 0;
  double get terlambatPercent => total > 0 ? terlambat / total : 0;
}

class AttendanceState {
  final bool isLoading;
  final String? error;
  final String? activeToken;
  final int? expiresInSeconds;
  final List<AttendanceRecord>? records;
  final AttendanceRecap? recap;
  final bool? scanSuccess;
  final String? scanMessage;
  final int scannedCount;
  final String? sessionId;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.activeToken,
    this.expiresInSeconds,
    this.records,
    this.recap,
    this.scanSuccess,
    this.scanMessage,
    this.scannedCount = 0,
    this.sessionId,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? activeToken,
    int? expiresInSeconds,
    List<AttendanceRecord>? records,
    AttendanceRecap? recap,
    bool? scanSuccess,
    String? scanMessage,
    int? scannedCount,
    String? sessionId,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeToken: activeToken ?? this.activeToken,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      records: records ?? this.records,
      recap: recap ?? this.recap,
      scanSuccess: scanSuccess ?? this.scanSuccess,
      scanMessage: scanMessage ?? this.scanMessage,
      scannedCount: scannedCount ?? this.scannedCount,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final Dio _dio;

  AttendanceNotifier(this._dio) : super(const AttendanceState());

  Future<String?> generateQr({
    required String scheduleId,
    String? classId,
    String? subjectId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post(
        ApiEndpoints.attendanceGenerate,
        data: {
          'scheduleId': scheduleId,
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
        },
      );
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          activeToken: data['token'] as String?,
          expiresInSeconds: data['expiresIn'] as int? ?? 30,
          sessionId: data['sessionId'] as String?,
          scannedCount: 0,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> scanQr(
    String token, {
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post(
        ApiEndpoints.attendanceScan,
        data: {
          'token': token,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(
        isLoading: false,
        scanSuccess: true,
        scanMessage: data?['message'] as String? ?? 'Absensi tercatat!',
      );
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(
        isLoading: false,
        scanSuccess: false,
        scanMessage: msg,
        error: msg,
      );
      return msg;
    }
  }

  Future<void> fetchMyAttendance() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.attendanceMy);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        records: items
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchClassAttendance(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('${ApiEndpoints.attendanceByClass}/$classId');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        records: items
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchRecap(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('${ApiEndpoints.attendanceRecap}/$classId');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final raw = data['data'] is Map
          ? data['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      state = state.copyWith(
        isLoading: false,
        recap: AttendanceRecap.fromJson(raw),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> deactivateSession(String sessionId) async {
    try {
      await _dio.post('${ApiEndpoints.attendanceSession}/$sessionId/deactivate');
      state = state.copyWith(activeToken: null, expiresInSeconds: null, sessionId: null);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<void> getActiveSession() async {
    try {
      final response = await _dio.get(ApiEndpoints.attendanceActiveSession);
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          activeToken: data['token'] as String?,
          expiresInSeconds: data['expiresIn'] as int?,
          sessionId: data['sessionId'] as String?,
          scannedCount: data['scannedCount'] as int? ?? 0,
        );
      }
    } catch (_) {}
  }

  Future<void> fetchScannedCount() async {
    if (state.sessionId == null) return;
    try {
      final response = await _dio.get(
        '${ApiEndpoints.attendanceSession}/${state.sessionId}/scanned',
      );
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          scannedCount: data['count'] as int? ?? state.scannedCount,
        );
      }
    } catch (_) {}
  }

  void resetScanSuccess() {
    state = state.copyWith(scanSuccess: null, scanMessage: null);
  }

  void resetSession() {
    state = const AttendanceState();
  }

  void clearError() {
    state = state.copyWith(error: null, clearError: true);
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendanceNotifier(dio);
});
