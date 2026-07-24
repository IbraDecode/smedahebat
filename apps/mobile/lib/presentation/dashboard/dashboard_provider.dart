import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class TodaySchedule {
  final String subject;
  final String teacher;
  final String room;
  final String startTime;
  final String endTime;
  final String? nextSubject;

  const TodaySchedule({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.startTime,
    required this.endTime,
    this.nextSubject,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      subject: json['subject'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      room: json['room'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      nextSubject: json['nextSubject'] as String?,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final String date;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class Task {
  final String id;
  final String name;
  final String subject;
  final String deadline;
  final String status;

  const Task({
    required this.id,
    required this.name,
    required this.subject,
    required this.deadline,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class DashboardData {
  final String greeting;
  final Map<String, dynamic> stats;
  final TodaySchedule? todaySchedule;
  final List<Announcement> recentAnnouncements;
  final List<Task> upcomingTasks;
  final Map<String, dynamic>? tomorrowSchedule;

  const DashboardData({
    this.greeting = '',
    this.stats = const {},
    this.todaySchedule,
    this.recentAnnouncements = const [],
    this.upcomingTasks = const [],
    this.tomorrowSchedule,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      greeting: json['greeting'] as String? ?? '',
      stats: json['stats'] is Map ? json['stats'] as Map<String, dynamic> : {},
      todaySchedule: json['todaySchedule'] != null
          ? TodaySchedule.fromJson(json['todaySchedule'] as Map<String, dynamic>)
          : null,
      recentAnnouncements: (json['recentAnnouncements'] as List<dynamic>?)
              ?.map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcomingTasks: (json['upcomingTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tomorrowSchedule: json['tomorrowSchedule'] as Map<String, dynamic>?,
    );
  }
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardData? data;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    DashboardData? data,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Dio _dio;

  DashboardNotifier(this._dio) : super(const DashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.dashboard);
      final rawData = response.data is Map
          ? (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          : null;
      state = state.copyWith(
        isLoading: false,
        data: rawData != null ? DashboardData.fromJson(rawData) : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> markAnnouncementRead(String id) async {
    try {
      await _dio.patch('${ApiEndpoints.notifications}/$id/read');
      await fetchDashboard();
    } catch (_) {}
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardNotifier(dio)..fetchDashboard();
});
