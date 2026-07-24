import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';

class Subject {
  final String id;
  final String name;
  final String code;
  final String? teacher;
  final String? className;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.teacher,
    this.className,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      teacher: json['teacher'] as String?,
      className: json['class'] as String?,
    );
  }
}

class SubjectsState {
  final bool isLoading;
  final String? error;
  final List<Subject> subjects;

  const SubjectsState({
    this.isLoading = false,
    this.error,
    this.subjects = const [],
  });

  SubjectsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Subject>? subjects,
  }) {
    return SubjectsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      subjects: subjects ?? this.subjects,
    );
  }
}

class SubjectsNotifier extends StateNotifier<SubjectsState> {
  final Dio _dio;

  SubjectsNotifier(this._dio) : super(const SubjectsState());

  Future<void> fetchSubjects() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.schedule);
      final List<dynamic> items = response.data['data'] is List
          ? response.data['data'] as List<dynamic>
          : [];
      state = state.copyWith(
        isLoading: false,
        subjects: items
            .map((e) => Subject.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }
}

final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  final dio = ref.watch(dioProvider);
  return SubjectsNotifier(dio)..fetchSubjects();
});

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mata Pelajaran')),
      body: state.isLoading
          ? _buildShimmerLoading()
          : state.error != null
              ? ErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(subjectsProvider.notifier).fetchSubjects(),
                )
              : state.subjects.isEmpty
                  ? const EmptyState(
                      icon: Icons.book_outlined,
                      title: 'Belum ada mata pelajaran',
                      subtitle: 'Mata pelajaran akan muncul jika sudah tersedia',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.subjects.length,
                      itemBuilder: (context, index) {
                        final subject = state.subjects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SubjectCard(subject: subject),
                        );
                      },
                    ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 88),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final initials = subject.name.isNotEmpty
        ? subject.name.split(' ').map((w) => w[0]).take(2).join()
        : '??';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subject.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
          if (subject.teacher != null || subject.className != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (subject.teacher != null)
                  Text(
                    subject.teacher!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                if (subject.className != null)
                  Text(
                    subject.className!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
