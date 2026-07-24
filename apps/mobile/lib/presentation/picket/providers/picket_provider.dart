import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../academic/providers/schedule_provider.dart';

class PicketMember {
  final String id;
  final String name;
  final String? nis;
  final bool isDone;
  final DateTime? doneAt;

  const PicketMember({
    required this.id,
    this.name = '',
    this.nis,
    this.isDone = false,
    this.doneAt,
  });

  factory PicketMember.fromJson(Map<String, dynamic> json) {
    return PicketMember(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nis: json['nis'] as String?,
      isDone: json['isDone'] as bool? ?? false,
      doneAt: json['doneAt'] != null ? DateTime.tryParse(json['doneAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nis': nis,
    };
  }
}

class PicketDay {
  final Day day;
  final bool isToday;
  final List<PicketMember> members;

  const PicketDay({
    required this.day,
    this.isToday = false,
    this.members = const [],
  });

  factory PicketDay.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return PicketDay(
      day: Day.fromString(json['day'] as String? ?? 'senin'),
      isToday: json['isToday'] as bool? ?? false,
      members: membersRaw
          .map((e) => PicketMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PicketLogItem {
  final String id;
  final String date;
  final String day;
  final String status;
  final String? time;
  final String? studentName;

  const PicketLogItem({
    required this.id,
    this.date = '',
    this.day = '',
    this.status = '',
    this.time,
    this.studentName,
  });

  factory PicketLogItem.fromJson(Map<String, dynamic> json) {
    return PicketLogItem(
      id: json['id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      day: json['day'] as String? ?? '',
      status: json['status'] as String? ?? '',
      time: json['time'] as String?,
      studentName: json['studentName'] as String?,
    );
  }
}

class PicketStats {
  final int total;
  final int done;
  final int missed;
  final double percentage;

  const PicketStats({
    this.total = 0,
    this.done = 0,
    this.missed = 0,
    this.percentage = 0,
  });

  factory PicketStats.fromJson(Map<String, dynamic> json) {
    return PicketStats(
      total: json['total'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PicketState {
  final bool isLoading;
  final String? error;
  final List<PicketDay> mySchedule;
  final List<PicketMember> todayPicket;
  final List<PicketLogItem> history;
  final PicketStats? stats;
  final List<PicketDay> classSchedule;
  final List<PicketMember> classMembers;

  const PicketState({
    this.isLoading = false,
    this.error,
    this.mySchedule = const [],
    this.todayPicket = const [],
    this.history = const [],
    this.stats,
    this.classSchedule = const [],
    this.classMembers = const [],
  });

  PicketState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<PicketDay>? mySchedule,
    List<PicketMember>? todayPicket,
    List<PicketLogItem>? history,
    PicketStats? stats,
    bool clearStats = false,
    List<PicketDay>? classSchedule,
    List<PicketMember>? classMembers,
  }) {
    return PicketState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      mySchedule: mySchedule ?? this.mySchedule,
      todayPicket: todayPicket ?? this.todayPicket,
      history: history ?? this.history,
      stats: clearStats ? null : (stats ?? this.stats),
      classSchedule: classSchedule ?? this.classSchedule,
      classMembers: classMembers ?? this.classMembers,
    );
  }
}

class PicketNotifier extends StateNotifier<PicketState> {
  final Dio _dio;

  PicketNotifier(this._dio) : super(const PicketState());

  Future<void> fetchMySchedule() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.picketMy);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        mySchedule: items
            .map((e) => PicketDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchTodayPicket(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.picketToday}/$classId',
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        todayPicket: items
            .map((e) => PicketMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchClassSchedule(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.picket}/class/$classId',
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        classSchedule: items
            .map((e) => PicketDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<String?> checklist(String picketId, {String? note}) async {
    try {
      await _dio.post(
        '${ApiEndpoints.picket}/$picketId/checklist',
        data: note != null ? {'note': note} : null,
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> createPicket({
    required String classId,
    required String day,
    required List<String> studentIds,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.picket,
        data: {
          'classId': classId,
          'day': day,
          'studentIds': studentIds,
        },
      );
      await fetchClassSchedule(classId);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> removePicket(String picketId) async {
    try {
      await _dio.delete('${ApiEndpoints.picket}/$picketId');
      state = state.copyWith(
        mySchedule: state.mySchedule
            .map((d) => PicketDay(
                  day: d.day,
                  isToday: d.isToday,
                  members: d.members.where((m) => m.id != picketId).toList(),
                ))
            .toList(),
        classSchedule: state.classSchedule
            .map((d) => PicketDay(
                  day: d.day,
                  isToday: d.isToday,
                  members: d.members.where((m) => m.id != picketId).toList(),
                ))
            .toList(),
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<void> fetchHistory({String? classId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final String endpoint;
      if (classId != null) {
        endpoint = '${ApiEndpoints.picketHistory}/$classId';
      } else {
        endpoint = ApiEndpoints.picketHistory;
      }
      final response = await _dio.get(endpoint);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        history: items
            .map((e) => PicketLogItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchStats(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.picketStats}/$classId',
      );
      final data = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(
        isLoading: false,
        stats: data != null ? PicketStats.fromJson(data) : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchClassMembers(String classId) async {
    try {
      final response = await _dio.get('/classes/$classId/students');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        classMembers: items
            .map((e) => PicketMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (_) {}
  }

  Future<void> reorderMembers(String dayName, List<PicketMember> reordered) async {
    state = state.copyWith(
      classSchedule: state.classSchedule.map((d) {
        if (d.day.name == dayName) {
          return PicketDay(day: d.day, isToday: d.isToday, members: reordered);
        }
        return d;
      }).toList(),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final picketProvider = StateNotifierProvider<PicketNotifier, PicketState>((ref) {
  final dio = ref.watch(dioProvider);
  return PicketNotifier(dio);
});
