import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/grade_provider.dart';

class GradeComponentScreen extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? classId;

  const GradeComponentScreen({super.key, this.subjectId, this.classId});

  @override
  ConsumerState<GradeComponentScreen> createState() => _GradeComponentScreenState();
}

class _GradeComponentScreenState extends ConsumerState<GradeComponentScreen> {
  String? _selectedSubjectId;
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.subjectId;
    _selectedClassId = widget.classId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradeProvider.notifier).fetchComponents(
        subjectId: _selectedSubjectId,
        classId: _selectedClassId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Komponen Nilai')),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/grade/components/create', extra: {
          if (_selectedSubjectId != null) 'subjectId': _selectedSubjectId,
          if (_selectedClassId != null) 'classId': _selectedClassId,
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(GradeState state) {
    if (state.isLoading && state.components.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading.listItem(height: 80),
        ),
      );
    }

    if (state.error != null && state.components.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(gradeProvider.notifier).fetchComponents(
          subjectId: _selectedSubjectId,
          classId: _selectedClassId,
        ),
      );
    }

    if (state.components.isEmpty) {
      return EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'Belum ada komponen',
        subtitle: 'Tambahkan komponen nilai untuk memulai',
        actionLabel: 'Tambah',
        onAction: () => context.push('/grade/components/create', extra: {
          if (_selectedSubjectId != null) 'subjectId': _selectedSubjectId,
          if (_selectedClassId != null) 'classId': _selectedClassId,
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gradeProvider.notifier).fetchComponents(
        subjectId: _selectedSubjectId,
        classId: _selectedClassId,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.components.length,
        itemBuilder: (context, index) {
          final c = state.components[index];
          return Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Komponen'),
                  content: Text('Yakin ingin menghapus "${c.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              ref.read(gradeProvider.notifier).deleteComponent(c.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.push('/grade/components/${c.id}/edit', extra: {
                  'id': c.id,
                  'name': c.name,
                  'type': c.type,
                  'weight': c.weight,
                  'maxScore': c.maxScore,
                  'subjectId': c.subjectId,
                  'classId': c.classId,
                }),
                title: Text(c.name),
                subtitle: Text('${c.subjectName} - ${c.className}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor(c.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.type,
                        style: TextStyle(
                          fontSize: 11,
                          color: _typeColor(c.type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${c.weight}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/${c.maxScore}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Tugas':
        return AppColors.primary;
      case 'UTS':
        return AppColors.warning;
      case 'UAS':
        return AppColors.error;
      case 'Praktik':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
