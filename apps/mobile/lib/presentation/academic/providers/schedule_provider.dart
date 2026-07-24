import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

enum Day {
  senin,
  selasa,
  rabu,
  kamis,
  jumat,
  sabtu;

  String get label {
    switch (this) {
      case Day.senin:
        return 'Senin';
      case Day.selasa:
        return 'Selasa';
      case Day.rabu:
        return 'Rabu';
      case Day.kamis:
        return 'Kamis';
      case Day.jumat:
        return 'Jumat';
      case Day.sabtu:
        return 'Sabtu';
    }
  }

  static Day fromString(String value) {
    return Day.values.firstWhere(
      (d) => d.name == value.toLowerCase(),
      orElse: () => Day.senin,
    );
  }

  static Day current() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday:
        return Day.senin;
      case DateTime.tuesday:
        return Day.selasa;
      case DateTime.wednesday:
        return Day.rabu;
      case DateTime.thursday:
        return Day.kamis;
      case DateTime.friday:
        return Day.jumat;
      case DateTime.saturday:
        return Day.sabtu;
      default:
        return Day.senin;
    }
  }

  static List<Day> get weekDays => Day.values;
}

enum ScheduleView { daily, weekly }

class ScheduleItem {
  final String id;
  final String subjectName;
  final String teacherName;
  final String classRoom;
  final String startTime;
  final String endTime;
  final Day day;

  const ScheduleItem({
    required this.id,
    this.subjectName = '',
    this.teacherName = '',
    this.classRoom = '',
    this.startTime = '00:00',
    this.endTime = '00:00',
    this.day = Day.senin,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id']?.toString() ?? '',
      subjectName: json['subjectName'] as String? ?? json['subject'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? json['teacher'] as String? ?? '',
      classRoom: json['classRoom'] as String? ?? json['room'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      day: Day.fromString(json['day'] as String? ?? 'senin'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'teacherName': teacherName,
      'classRoom': classRoom,
      'startTime': startTime,
      'endTime': endTime,
      'day': day.name,
    };
  }

  int get startMinutes {
    final parts = startTime.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  int get endMinutes {
    final parts = endTime.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }
}

class ScheduleState {
  final bool isLoading;
  final String? error;
  final List<ScheduleItem> todaySchedule;
  final Map<String, List<ScheduleItem>> weeklySchedule;
  final ScheduleView view;
  final Day selectedDay;
  final String? classId;
  final String? teacherId;

  const ScheduleState({
    this.isLoading = false,
    this.error,
    this.todaySchedule = const [],
    this.weeklySchedule = const {},
    this.view = ScheduleView.daily,
    this.selectedDay = Day.senin,
    this.classId,
    this.teacherId,
  });

  ScheduleState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<ScheduleItem>? todaySchedule,
    Map<String, List<ScheduleItem>>? weeklySchedule,
    ScheduleView? view,
    Day? selectedDay,
    String? classId,
    String? teacherId,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      todaySchedule: todaySchedule ?? this.todaySchedule,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      view: view ?? this.view,
      selectedDay: selectedDay ?? this.selectedDay,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Dio _dio;

  ScheduleNotifier(this._dio) : super(const ScheduleState());

  Future<void> fetchTodaySchedule() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.scheduleToday);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      state = state.copyWith(
        isLoading: false,
        todaySchedule: items
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchScheduleByClass(String classId, {Day? day}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      classId: classId,
    );
    try {
      final queryParams = <String, dynamic>{};
      if (day != null) queryParams['day'] = day.name;
      final response = await _dio.get(
        '${ApiEndpoints.scheduleByClass}/$classId',
        queryParameters: queryParams,
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      final scheduleList = items
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final weeklyMap = _buildWeeklyMap(scheduleList);
      state = state.copyWith(
        isLoading: false,
        weeklySchedule: weeklyMap,
        todaySchedule: scheduleList,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchScheduleByTeacher(String teacherId, {Day? day}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      teacherId: teacherId,
    );
    try {
      final queryParams = <String, dynamic>{};
      if (day != null) queryParams['day'] = day.name;
      final response = await _dio.get(
        '${ApiEndpoints.scheduleByTeacher}/$teacherId',
        queryParameters: queryParams,
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      final scheduleList = items
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final weeklyMap = _buildWeeklyMap(scheduleList);
      state = state.copyWith(
        isLoading: false,
        weeklySchedule: weeklyMap,
        todaySchedule: scheduleList,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Map<String, List<ScheduleItem>> _buildWeeklyMap(List<ScheduleItem> items) {
    final map = <String, List<ScheduleItem>>{};
    for (final day in Day.values) {
      map[day.name] = [];
    }
    for (final item in items) {
      map[item.day.name]?.add(item);
    }
    for (final day in map.keys) {
      map[day]!.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    return map;
  }

  void toggleView() {
    state = state.copyWith(
      view: state.view == ScheduleView.daily
          ? ScheduleView.weekly
          : ScheduleView.daily,
    );
  }

  void setView(ScheduleView view) {
    state = state.copyWith(view: view);
  }

  void setSelectedDay(Day day) {
    state = state.copyWith(selectedDay: day);
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final dio = ref.watch(dioProvider);
  return ScheduleNotifier(dio);
});
