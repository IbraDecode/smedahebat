import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/grade_provider.dart';
import '../widgets/grade_badge.dart';
import '../widgets/rapor_pdf_preview.dart';

class RaporScreen extends ConsumerStatefulWidget {
  final String? raporId;

  const RaporScreen({super.key, this.raporId});

  @override
  ConsumerState<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends ConsumerState<RaporScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (widget.raporId != null) {
        return;
      }
      if (auth.role == 'student') {
        ref.read(gradeProvider.notifier).fetchMyRapor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);
    final auth = ref.watch(authProvider);
    final isStudent = auth.role == 'student';
    final isWaliKelas = auth.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor'),
        actions: [
          if (isWaliKelas)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate Rapor',
              onPressed: () => context.push('/grade/rapor/generate'),
            ),
        ],
      ),
      body: widget.raporId != null
          ? _buildRaporDetail(state)
          : isStudent
              ? _buildStudentView(state)
              : _buildTeacherView(state, isWaliKelas),
    );
  }

  Widget _buildStudentView(GradeState state) {
    if (state.isLoading && state.myRapor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.myRapor == null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(gradeProvider.notifier).fetchMyRapor(),
      );
    }

    final rapor = state.myRapor;
    if (rapor == null) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: 'Rapor belum tersedia',
        subtitle: 'Hubungi wali kelas untuk informasi lebih lanjut',
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (rapor.status == 'draft')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Rapor masih dalam proses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ],
              ),
            ),
          RaporPdfPreview(rapor: rapor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur export akan segera tersedia')),
                );
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Bagikan / Export'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTeacherView(GradeState state, bool isWaliKelas) {
    if (state.isLoading && state.classRapors.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading.listItem(height: 80),
        ),
      );
    }

    if (state.classRapors.isEmpty) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: 'Belum ada rapor',
        subtitle: 'Generate rapor untuk kelas yang Anda wali',
        actionLabel: isWaliKelas ? 'Generate Rapor' : null,
        onAction: isWaliKelas ? () => context.push('/grade/rapor/generate') : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.classRapors.length,
        itemBuilder: (_, i) {
          final r = state.classRapors[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  r.studentName.isNotEmpty ? r.studentName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(r.studentName),
              subtitle: Text('NIS: ${r.studentNis} | ${r.className}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradeBadge(score: r.average, size: 28),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.status == 'published'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      r.status == 'published' ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: 10,
                        color: r.status == 'published' ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () => context.push('/grade/rapor/${r.id}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRaporDetail(GradeState state) {
    if (state.isLoading && state.myRapor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () {},
      );
    }

    final rapor = state.classRapors.where((r) => r.id == widget.raporId).firstOrNull
        ?? state.myRapor;

    if (rapor == null) {
      return const Center(child: Text('Rapor tidak ditemukan'));
    }

    return SingleChildScrollView(
      child: RaporPdfPreview(rapor: rapor),
    );
  }
}
