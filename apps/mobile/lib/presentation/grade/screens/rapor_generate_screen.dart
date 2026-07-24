import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../providers/grade_provider.dart';
import '../widgets/grade_badge.dart';

class RaporGenerateScreen extends ConsumerStatefulWidget {
  const RaporGenerateScreen({super.key});

  @override
  ConsumerState<RaporGenerateScreen> createState() => _RaporGenerateScreenState();
}

class _RaporGenerateScreenState extends ConsumerState<RaporGenerateScreen> {
  String? _selectedClassId;
  String _semester = '1';
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Rapor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Rapor Kelas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih kelas dan semester untuk generate rapor siswa.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            items: const [],
            onChanged: (v) => setState(() => _selectedClassId = v),
            decoration: const InputDecoration(labelText: 'Pilih Kelas'),
            hint: const Text('Kelas akan dimuat otomatis'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _semester,
            items: ['1', '2']
                .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _semester = v);
            },
            decoration: const InputDecoration(labelText: 'Semester'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(_isGenerating ? 'Memproses...' : 'Generate Rapor'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Menghitung nilai dan membuat rapor...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (state.classRapors.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Hasil Generate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.classRapors.map((r) => _buildRaporItem(r, context)),
          ],
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    final error = await ref.read(gradeProvider.notifier).generateRapor(
      classId: _selectedClassId ?? '',
      academicYearId: '',
      semester: _semester,
    );
    setState(() => _isGenerating = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else if (_selectedClassId != null) {
      ref.read(gradeProvider.notifier).fetchClassRapors(_selectedClassId!);
    }
  }

  Widget _buildRaporItem(ReportCard r, BuildContext context) {
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
        subtitle: Text('NIS: ${r.studentNis}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradeBadge(score: r.average, size: 32),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 20),
              onPressed: () => context.push('/grade/rapor/${r.id}'),
            ),
            if (r.status != 'published')
              IconButton(
                icon: Icon(Icons.publish, size: 20, color: AppColors.primary),
                onPressed: () => _publish(r.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publikasi Rapor'),
        content: const Text('Setelah dipublikasi, siswa dapat melihat rapor. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publikasi')),
        ],
      ),
    );
    if (confirm == true) {
      final error = await ref.read(gradeProvider.notifier).publishRapor(id);
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
