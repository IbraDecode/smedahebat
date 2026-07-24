import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final double attendance;
  final int completedAssignments;
  final int totalAssignments;
  final int enrolledCourses;
  final double gpa;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.attendance = 0,
    this.completedAssignments = 0,
    this.totalAssignments = 0,
    this.enrolledCourses = 0,
    this.gpa = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    double? attendance,
    int? completedAssignments,
    int? totalAssignments,
    int? enrolledCourses,
    double? gpa,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      attendance: attendance ?? this.attendance,
      completedAssignments: completedAssignments ?? this.completedAssignments,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      gpa: gpa ?? this.gpa,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isLoading: false,
        attendance: 85,
        completedAssignments: 4,
        totalAssignments: 6,
        enrolledCourses: 6,
        gpa: 3.8,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
