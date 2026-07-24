import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/assignment_provider.dart';
import '../widgets/grade_input.dart';
import '../widgets/submission_status_badge.dart';

class GradeSubmissionScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final String submissionId;

  const GradeSubmissionScreen({
    super.key,
    required this.assignmentId,
    required this.submissionId,
  });

  @override
  ConsumerState<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends ConsumerState<GradeSubmissionScreen> {
  final _gradeInputKey = GlobalKey<GradeInputState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Tugas'),
      ),
      body: state.isLoading && state.submissions.isEmpty
          ? _buildShimmer()
          : state.error != null && state.submissions.isEmpty
              ? ErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(assignmentProvider.notifier).fetchSubmissions(widget.assignmentId),
                )
              : _buildContent(context, state),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(height: 24, width: 200),
        const SizedBox(height: 16),
        ShimmerBox(height: 16),
        const SizedBox(height: 8),
        ShimmerBox(height: 120),
        const SizedBox(height: 24),
        ShimmerBox(height: 200),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AssignmentState state) {
    final submission = state.submissions.firstWhere(
      (s) => s.id == widget.submissionId,
      orElse: () => SubmissionItem(
        id: widget.submissionId,
        submittedAt: DateTime.now(),
      ),
    );

    final detail = state.detail;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentInfo(context, submission),
          const SizedBox(height: 20),
          _buildSubmissionContent(context, submission),
          const SizedBox(height: 24),
          GradeInput(
            key: _gradeInputKey,
            maxScore: detail?.maxScore ?? 100,
            initialScore: submission.score,
            initialFeedback: submission.feedback,
          ),
          const SizedBox(height: 32),
          AppButton(
            label: submission.score != null ? 'Perbarui Nilai' : 'Simpan Nilai',
            isLoading: _isSubmitting,
            onPressed: () => _submitGrade(submission),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(BuildContext context, SubmissionItem submission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              submission.studentName.isNotEmpty ? submission.studentName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (submission.studentNis.isNotEmpty)
                  Text(
                    'NIS: ${submission.studentNis}',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
              ],
            ),
          ),
          SubmissionStatusBadge(status: submission.status),
        ],
      ),
    );
  }

  Widget _buildSubmissionContent(BuildContext context, SubmissionItem submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jawaban Siswa',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Dikumpulkan: ${DateFormat('d MMM yyyy, HH:mm', 'id').format(submission.submittedAt)}',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                submission.feedback ?? 'Tidak ada jawaban teks',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitGrade(SubmissionItem submission) async {
    final gradeInput = _gradeInputKey.currentState;
    if (gradeInput == null) return;

    if (!gradeInput.validate()) return;

    final score = gradeInput.score;
    final feedback = gradeInput.feedback;

    if (score == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai harus diisi'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final error = await ref.read(assignmentProvider.notifier).gradeSubmission(
      widget.submissionId,
      score,
      feedback,
    );

    setState(() => _isSubmitting = false);

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai berhasil disimpan')),
      );
      Navigator.pop(context);
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $error'), backgroundColor: AppColors.error),
      );
    }
  }
}
