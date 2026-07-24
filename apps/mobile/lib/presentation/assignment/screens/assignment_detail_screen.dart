import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/assignment_provider.dart';
import '../widgets/submission_status_badge.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const AssignmentDetailScreen({super.key, required this.id});

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  final _contentController = TextEditingController();
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).fetchAssignmentDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final auth = ref.watch(authProvider);
    final isTeacher = auth.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(state.detail?.title ?? 'Detail Tugas'),
        actions: [
          if (isTeacher && state.detail != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/assignments/${widget.id}/edit', extra: {
                    'title': state.detail!.title,
                    'description': state.detail!.description,
                    'subjectName': state.detail!.subjectName,
                    'className': state.detail!.className,
                    'deadline': state.detail!.deadline.toIso8601String(),
                    'maxScore': state.detail!.maxScore,
                  });
                } else if (value == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                )),
                const PopupMenuItem(value: 'delete', child: ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title: Text('Hapus', style: TextStyle(color: AppColors.error)),
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
        ],
      ),
      body: state.isLoading && state.detail == null
          ? _buildShimmer()
          : state.error != null && state.detail == null
              ? ErrorState(
                  message: state.error!,
                  onRetry: () => ref.read(assignmentProvider.notifier).fetchAssignmentDetail(widget.id),
                )
              : _buildContent(context, state, isTeacher),
    );
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Apakah anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final error = await ref.read(assignmentProvider.notifier).deleteAssignment(widget.id);
      if (error == null && mounted) {
        context.pop();
      }
    }
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(height: 24, width: 200),
        const SizedBox(height: 16),
        ShimmerBox(height: 16),
        const SizedBox(height: 8),
        ShimmerBox(height: 16, width: 150),
        const SizedBox(height: 24),
        ShimmerBox(height: 120),
        const SizedBox(height: 24),
        ShimmerBox(height: 200),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AssignmentState state, bool isTeacher) {
    final detail = state.detail!;
    final now = DateTime.now();
    final isPastDeadline = detail.deadline.isBefore(now);

    return RefreshIndicator(
      onRefresh: () => ref.read(assignmentProvider.notifier).fetchAssignmentDetail(widget.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, detail),
            const SizedBox(height: 20),
            _buildInfoSection(context, detail, state.mySubmission),
            const SizedBox(height: 20),
            if (detail.description.isNotEmpty) _buildDescriptionSection(context, detail),
            if (detail.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildAttachmentsSection(context, detail),
            ],
            const SizedBox(height: 24),
            if (isTeacher)
              _buildTeacherSection(context, state, detail)
            else
              _buildStudentSection(context, state, detail, isPastDeadline),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AssignmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SubmissionStatusBadge(
          status: detail.myStatus ?? SubmissionStatus.pending,
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, AssignmentDetail detail, SubmissionDetail? mySubmission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(Icons.book_outlined, 'Mata Pelajaran', detail.subjectName),
          const Divider(height: 20),
          _infoRow(Icons.meeting_room_outlined, 'Kelas', detail.className),
          const Divider(height: 20),
          _infoRow(Icons.person_outline, 'Guru', detail.teacherName),
          const Divider(height: 20),
          _infoRow(Icons.access_time, 'Batas Waktu', DateFormat('d MMM yyyy, HH:mm', 'id').format(detail.deadline)),
          const Divider(height: 20),
          _infoRow(Icons.score_outlined, 'Nilai Maksimal', '${detail.maxScore}'),
          if (mySubmission != null && mySubmission.score != null) ...[
            const Divider(height: 20),
            _infoRow(Icons.grading_outlined, 'Nilai', '${mySubmission.score} / ${detail.maxScore}'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, AssignmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          detail.description,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(BuildContext context, AssignmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...detail.attachments.map(
          (a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 20, color: AppColors.primary),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherSection(BuildContext context, AssignmentState state, AssignmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pengumpulan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${detail.gradedCount}/${detail.totalSubmissions} dinilai',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${detail.totalSubmissions} dari ${detail.totalStudents} siswa',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Lihat Pengumpulan',
            icon: Icons.people_outline,
            onPressed: () {
              ref.read(assignmentProvider.notifier).fetchSubmissions(widget.id);
              _showSubmissionsSheet(context, state);
            },
          ),
        ),
        if (state.submissions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Daftar Pengumpulan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...state.submissions.map(
            (s) => _submissionItem(context, s),
          ),
        ],
      ],
    );
  }

  void _showSubmissionsSheet(BuildContext context, AssignmentState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final submissions = state.submissions;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengumpulan (${submissions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: submissions.isEmpty
                    ? const Center(child: Text('Belum ada pengumpulan'))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: submissions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = submissions[index];
                          return _submissionItem(context, s);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _submissionItem(BuildContext context, SubmissionItem s) {
    return InkWell(
      onTap: () => context.push('/assignments/${widget.id}/grade/${s.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.studentName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (s.studentNis.isNotEmpty)
                    Text(
                      'NIS: ${s.studentNis}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (s.score != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${s.score}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else
              SubmissionStatusBadge(status: s.status, fontSize: 10),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSection(BuildContext context, AssignmentState state, AssignmentDetail detail, bool isPastDeadline) {
    final mySubmission = state.mySubmission;

    if (mySubmission != null && mySubmission.status != SubmissionStatus.pending) {
      return _buildSubmissionResult(context, mySubmission, detail);
    }

    return _buildSubmissionForm(context, isPastDeadline, state.isLoading);
  }

  Widget _buildSubmissionForm(BuildContext context, bool isPastDeadline, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengumpulan Tugas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Jawaban',
          hint: 'Tulis jawaban anda...',
          maxLines: 5,
          controller: _contentController,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedFilePath != null
                      ? _selectedFilePath!.split('/').last
                      : 'Tambah Lampiran',
                  style: TextStyle(
                    color: _selectedFilePath != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                if (_selectedFilePath != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilePath = null),
                    child: const Icon(Icons.close, size: 18, color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isPastDeadline) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Batas waktu telah lewat. Tugas akan ditandai sebagai terlambat.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: 'Kumpulkan Tugas',
          isLoading: isLoading,
          onPressed: _submitAssignment,
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _selectedFilePath = '/tmp/sample_file.pdf';
    });
  }

  Future<void> _submitAssignment() async {
    final error = await ref.read(assignmentProvider.notifier).submitAssignment(
      widget.id,
      content: _contentController.text.trim(),
      filePath: _selectedFilePath,
    );
    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
      );
    }
  }

  Widget _buildSubmissionResult(BuildContext context, SubmissionDetail submission, AssignmentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengumpulan Anda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
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
                  SubmissionStatusBadge(status: submission.status),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM HH:mm', 'id').format(submission.submittedAt),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
              if (submission.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  submission.content,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
              if (submission.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...submission.attachments.map(
                  (a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.name, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (submission.score != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nilai', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${submission.score} / ${detail.maxScore}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
              if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text(
                  'Umpan Balik',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  submission.feedback!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
