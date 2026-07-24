import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';

class SchoolClass {
  final String id;
  final String name;
  final String? room;
  final int studentCount;
  final String? waliKelas;

  const SchoolClass({
    required this.id,
    required this.name,
    this.room,
    this.studentCount = 0,
    this.waliKelas,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      room: json['room'] as String?,
      studentCount: json['studentCount'] as int? ?? 0,
      waliKelas: json['waliKelas'] as String?,
    );
  }
}

class ClassesState {
  final bool isLoading;
  final String? error;
  final List<SchoolClass> classes;
  final String? gradeFilter;

  const ClassesState({
    this.isLoading = false,
    this.error,
    this.classes = const [],
    this.gradeFilter,
  });

  ClassesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<SchoolClass>? classes,
    String? gradeFilter,
  }) {
    return ClassesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      classes: classes ?? this.classes,
      gradeFilter: gradeFilter ?? this.gradeFilter,
    );
  }
}

class ClassesNotifier extends StateNotifier<ClassesState> {
  final Dio _dio;

  ClassesNotifier(this._dio) : super(const ClassesState());

  Future<void> fetchClasses({String? grade}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      gradeFilter: grade,
    );
    try {
      final response = await _dio.get(
        ApiEndpoints.users,
        queryParameters: {
          'role': 'student',
          if (grade != null) 'grade': grade,
          'groupBy': 'class',
        },
      );
      final List<dynamic> items = response.data['data'] is List
          ? response.data['data'] as List<dynamic>
          : [];
      state = state.copyWith(
        isLoading: false,
        classes: items
            .map((e) => SchoolClass.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }
}

final classesProvider =
    StateNotifierProvider<ClassesNotifier, ClassesState>((ref) {
  final dio = ref.watch(dioProvider);
  return ClassesNotifier(dio)..fetchClasses();
});

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddClassDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: state.gradeFilter == null,
                  onTap: () =>
                      ref.read(classesProvider.notifier).fetchClasses(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Kelas 10',
                  selected: state.gradeFilter == '10',
                  onTap: () => ref
                      .read(classesProvider.notifier)
                      .fetchClasses(grade: '10'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Kelas 11',
                  selected: state.gradeFilter == '11',
                  onTap: () => ref
                      .read(classesProvider.notifier)
                      .fetchClasses(grade: '11'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Kelas 12',
                  selected: state.gradeFilter == '12',
                  onTap: () => ref
                      .read(classesProvider.notifier)
                      .fetchClasses(grade: '12'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? _buildShimmerLoading()
                : state.error != null
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(classesProvider.notifier).fetchClasses(),
                      )
                    : state.classes.isEmpty
                        ? const EmptyState(
                            icon: Icons.meeting_room_outlined,
                            title: 'Belum ada kelas',
                            subtitle: 'Tambahkan kelas baru',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.classes.length,
                            itemBuilder: (context, index) {
                              final c = state.classes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ClassCard(schoolClass: c),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 88),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'X IPA 1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                hintText: '201',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(classesProvider.notifier).fetchClasses();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final SchoolClass schoolClass;

  const _ClassCard({required this.schoolClass});

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              schoolClass.name.isNotEmpty
                  ? schoolClass.name.split(' ').first
                  : '?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondary,
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
                  schoolClass.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (schoolClass.room != null) ...[
                      Icon(Icons.room_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        'Ruangan ${schoolClass.room}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.people_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${schoolClass.studentCount} Siswa',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (schoolClass.waliKelas != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Wali Kelas',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
                Text(
                  schoolClass.waliKelas!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
